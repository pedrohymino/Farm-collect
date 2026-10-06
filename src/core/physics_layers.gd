class_name PhysicsLayers
extends RefCounted
## Collision layer bits. Helpers live on their own layer so they never block the player,
## while zones add WORKERS to their mask to notice them.

const WORLD: int = 1
const WORKERS: int = 2
