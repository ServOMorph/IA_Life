import json
import os
import socket
import subprocess
import time
from pathlib import Path

import gymnasium as gym
from gymnasium import spaces


ROOT = Path(__file__).resolve().parents[1]


class T0GymEnv(gym.Env):
    metadata = {"render_modes": []}

    def __init__(self, godot="godot", port=None, timeout=10.0, scene="tools/t0_gym_server.tscn", diagnostics=False):
        super().__init__()
        self.action_space = spaces.Discrete(8)
        self.observation_space = spaces.Dict({
            "resource_sector": spaces.Discrete(8),
            "resource_visible": spaces.Discrete(2),
            "previous_action": spaces.Discrete(9),
        })
        self.timeout = timeout
        self.port = port or self._free_port()
        process_environment = os.environ.copy()
        for name in ("IA_LIFE_HEADLESS_CONFIG", "IA_LIFE_RL_MODE", "IA_LIFE_DEV_MODE", "IA_LIFE_GYM_DIAGNOSTICS"):
            process_environment.pop(name, None)
        if diagnostics:
            process_environment["IA_LIFE_GYM_DIAGNOSTICS"] = "1"
        self.process = subprocess.Popen(
            [godot, "--headless", "--fixed-fps", "60", "--path", str(ROOT), "--log-file", str(ROOT / "logs" / f"t0_gym_{self.port}.log"),
             "--scene", scene, "--", "--port", str(self.port)],
            cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, env=process_environment,
        )
        self.connection = None
        self.reader = None
        self.episode_id = None
        self.step_id = 0
        self.ended = True
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if self.process.poll() is not None:
                raise RuntimeError(f"Godot a quitté avec le code {self.process.returncode}: {self.process.stderr.read().decode(errors='replace')}")
            try:
                self.connection = socket.create_connection(("127.0.0.1", self.port), timeout=0.2)
                break
            except OSError:
                time.sleep(0.02)
        if self.connection is None:
            self.close()
            raise TimeoutError("Connexion au serveur Godot impossible")
        self.connection.settimeout(timeout)
        self.reader = self.connection.makefile("rb")

    @staticmethod
    def _free_port():
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0))
            return sock.getsockname()[1]

    def _request(self, payload):
        self.connection.sendall((json.dumps(payload) + "\n").encode())
        line = self.reader.readline()
        if not line:
            raise ConnectionError("Godot a fermé la connexion")
        response = json.loads(line)
        if response.get("type") == "error":
            raise RuntimeError(response.get("message", "Erreur du serveur Godot"))
        return response

    @staticmethod
    def _observation(response):
        raw = response["observation"]
        return {"resource_sector": int(raw["resource_sector"]),
                "resource_visible": int(bool(raw["resource_visible"])),
                "previous_action": int(raw["previous_action"])}

    def reset(self, *, seed=None, options=None):
        super().reset(seed=seed)
        if seed is None:
            seed = int(self.np_random.integers(0, 2**31))
        response = self._request({"type": "reset", "seed": int(seed)})
        self.episode_id = int(response["info"]["episode_id"])
        self.step_id = 0
        self.ended = False
        return self._observation(response), response["info"]

    def step(self, action):
        if self.ended:
            raise RuntimeError("reset requis avant step")
        if not self.action_space.contains(action):
            raise ValueError("action invalide")
        response = self._request({"type": "step", "episode_id": self.episode_id,
                                  "step_id": self.step_id, "action": int(action)})
        self.step_id += 1
        terminated = bool(response["terminated"])
        truncated = bool(response["truncated"])
        self.ended = terminated or truncated
        return self._observation(response), float(response["reward"]), terminated, truncated, response["info"]

    def close(self):
        if self.connection is not None:
            try:
                self._request({"type": "close"})
            except (OSError, ConnectionError, TimeoutError, RuntimeError):
                pass
            self.connection.close()
            self.connection = None
        if self.reader is not None:
            self.reader.close()
            self.reader = None
        if self.process.poll() is None:
            try:
                self.process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                self.process.terminate()
                self.process.wait(timeout=2)
        if self.process.stderr is not None:
            self.process.stderr.close()
