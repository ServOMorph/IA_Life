import numpy as np
from gymnasium import spaces

from t0_gym_env import T0GymEnv


class WorldGymEnv(T0GymEnv):
    def __init__(self, godot="godot", port=None, timeout=20.0, diagnostics=False):
        super().__init__(godot=godot, port=port, timeout=timeout,
                         scene="tools/world_gym_server.tscn", diagnostics=diagnostics)
        self.observation_space = spaces.Dict({
            "hunger": spaces.Box(0.0, 1.0, shape=(1,), dtype=np.float32),
            "inventory": spaces.Box(0.0, 1.0, shape=(1,), dtype=np.float32),
            "targets": spaces.Box(-1.0, 1.0, shape=(15,), dtype=np.float32),
            "memories": spaces.Box(-1.0, 1.0, shape=(15,), dtype=np.float32),
            "collision": spaces.Discrete(2),
            "progress": spaces.Box(-1.0, 1.0, shape=(1,), dtype=np.float32),
            "previous_action": spaces.Discrete(9),
        })

    @staticmethod
    def _observation(response):
        raw = response["observation"]
        return {
            "hunger": np.asarray(raw["hunger"], dtype=np.float32),
            "inventory": np.asarray(raw["inventory"], dtype=np.float32),
            "targets": np.asarray(raw["targets"], dtype=np.float32).reshape(15),
            "memories": np.asarray(raw["memories"], dtype=np.float32).reshape(15),
            "collision": int(raw["collision"]),
            "progress": np.asarray(raw["progress"], dtype=np.float32),
            "previous_action": int(raw["previous_action"]),
        }
