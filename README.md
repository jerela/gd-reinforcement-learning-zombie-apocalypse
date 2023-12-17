# Reinforcement learning in the zombie apocalypse

A Godot 4 implementation of a 2D world where two kinds of learning agents (survivors and zombies) evolve competitively.


- Zombies are rewarded when they hit (collide with) a survivor. When that happens, a survivor's health is reduced by one. If a survivor's health goes to zero, the survivor dies and the zombie is rewarded even more.
- Survivors are penalized when they are hit by a zombie. At the end of the training epoch, a survivor's fitness score is determined by how little they got hit. The survivors who is the furthest from the closest zombie is further rewarded to incentivize running away from zombies.
- Each training epoch, the survivor and zombie with the best fitnesses are kept. New agents are mutated from them by modifying their weights slightly, and one survivor and one zombie are reinitialized randomly.
- From random nonsensical weights that make the agents run in circles or stand mostly still, zombies learn to chase survivors and survivors learn to run away in ~100 epochs.
- Pretrained networks available in "zombie.txt" and "survivor.txt".

## How agents observe their surroundings
- Each agent has a raycast that it uses to sweep full circle around itself in 5 degree steps (like a rotating radar antenna).
- The raycast is used to detect other agents around the agent. Proximities of the other agents are calculated between 0 and 1, where 1 is at the same space and 0 is at the maximum range of the raycast. The local positions (in the scanning agent's coordinate system) of other agents are weighted by the proximity for zombies and survivors separately.
- The angle to the resulting proximity-weighted mean position of zombies or survivors is calculated, one for zombies and another for survivors.
- Cosines and sines of the angles are calculated to represent how strongly that position is to the side (and which side) of the agent, and how strongly that position is to the forward or back of the agent.
- These cosines and sines (which are conveniently normalized between -1 and 1 by the trigonometric functions) are fed to a shallow full connected feedforward neural network.
- The network outputs the control signals for forward/backward motion, strafe motion to the sides, and rotation. The outputs are normalized between -1 and 1 by the sigmoid function used in the nodes of the final layer in the network.

## Damage and agents
- Survivors have two health, zombies have three.
- An agent's movement is scaled by how much health they have remaining of their maximum health.
- When an agent's health goes to zero, they become a corpse. During the remainder of the training epoch, they cannot move or collide, and won't be observed by other agents as live survivors or zombies. Their fitness score is also penalized.

## Survivors
- In addition to movement controls, survivors have guns with three ammo each. A zombie will have to be shot three times to die, a survivor twice.
- A survivor's fitness score will be penalized for shooting other survivors and increased for shooting zombies.
- So far the survivors haven't learned to shoot zombies.

## Future ideas
- add colliders in the map and let the agents observe them
- let survivors get remaining ammo from corpses by touching them