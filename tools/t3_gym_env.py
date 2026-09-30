from world_gym_env import WorldGymEnv


class T3GymEnv(WorldGymEnv):
    def __init__(self, godot="godot", port=None, timeout=20.0, diagnostics=False):
        super().__init__(godot=godot, port=port, timeout=timeout,
                         diagnostics=diagnostics, scene="tools/t3_gym_server.tscn")
