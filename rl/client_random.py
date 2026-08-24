"""Smoke test TCP/JSONL IA_Life: un épisode Discrete(7) aléatoire."""
import argparse
import json
import random
import socket


def send(sock, payload):
    sock.sendall((json.dumps(payload) + "\n").encode("utf-8"))


def receive(reader):
    line = reader.readline()
    if not line:
        raise RuntimeError("Godot a fermé la connexion")
    message = json.loads(line)
    if message.get("type") == "error":
        raise RuntimeError(message["message"])
    return message


def run(seed, max_steps):
    rng = random.Random(seed)
    with socket.create_connection(("127.0.0.1", 11008), timeout=10) as sock:
        reader = sock.makefile("r", encoding="utf-8", newline="\n")
        send(sock, {"type": "reset", "seed": seed, "max_steps": max_steps})
        message = receive(reader)
        initial = message["observation"]
        total_reward = 0.0
        while not (message["terminated"] or message["truncated"]):
            send(sock, {"type": "step", "action": rng.randrange(7)})
            message = receive(reader)
            if any(not isinstance(value, (int, float)) or value != value for value in message["observation"]):
                raise RuntimeError("NaN ou observation non numérique")
            total_reward += message["reward"]
        print(json.dumps({"initial_observation": initial, "total_reward": total_reward, "terminated": message["terminated"], "truncated": message["truncated"], "info": message["info"]}, ensure_ascii=False))
        send(sock, {"type": "close"})
        receive(reader)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=1337)
    parser.add_argument("--max-steps", type=int, default=12)
    args = parser.parse_args()
    run(args.seed, args.max_steps)
