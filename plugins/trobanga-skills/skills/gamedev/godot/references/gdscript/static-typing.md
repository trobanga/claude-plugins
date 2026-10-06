# Static Typing: Errors and Traps

What the type checker rejects, and what it lets through that still fails at runtime. Checked against Godot 4.7 with default warning settings.

## Contents

- Parse errors
- Allowed, despite appearances
- Freed instances
- Casting and narrowing
- Containers
- Stricter projects

## Parse errors

The common ones are in the static-typing table of SKILL.md. Behind the "inferred from a Variant value" message is the warning `INFERENCE_ON_VARIANT`, which projects treat as an error by default. Besides `JSON.parse_string`, `pop_back` and `max`, these return Variant and so cannot feed `:=`: `pop_front`, `pick_random`, `front`, `back`, `min`, `clamp`, `Dictionary.get`, `Object.get`, `Object.call`, and any method call on an untyped value.

## Allowed, despite appearances

- `var speed: float = 100`: an int converts to float. The reverse narrows with warning `NARROWING_CONVERSION`.
- `typed_array[i]` keeps the element type, so `var e := enemies[0]` infers `Enemy`.
- Assigning an untyped `Array` (the result of `filter()` or `map()`) to an `Array[T]` variable is checked at runtime, element by element.
- Calling a method the static type does not declare (`node.take_damage()` on a `Node`) compiles and fails at runtime; only the optional `UNSAFE_METHOD_ACCESS` warning flags it.

## Freed instances

After `free()`/`queue_free()` completes, a variable still holds the dead reference. In 4.7 it compares equal to `null` and is falsy, but calling a method on it is a runtime error. `is_instance_valid(x)` is the one check that is correct for both null and freed references; use it for references to nodes you do not own (targets, other entities). `queue_free()` frees at the end of the frame, so a node is still valid in the same frame; check `is_queued_for_deletion()` if that matters.

## Casting and narrowing

- `x as T` returns `null` when `x` is an object of another type; for built-in types it converts or errors. Check the result before use.
- `if x is Enemy:` does not narrow `x` for the type checker; cast once into a typed local: `var enemy := x as Enemy`, then `if enemy:`.
- Enums are ints at runtime. `var m: Mode = 7` is accepted; validate values that come from files.

## Containers

- `Array[T]` for lists, `Dictionary[K, V]` (4.4+) for maps, `PackedVector2Array`, `PackedFloat32Array` and friends for large numeric data.
- Nested typed collections (`Array[Array[int]]`) do not exist; use `Array[PackedInt32Array]` or a small class.
- A `const` array or dictionary is read-only; mutating it is a runtime error.
- `for item: Item in items:` types the loop variable when `items` is untyped.

## Stricter projects

Project Settings → Debug → GDScript: set `untyped_declaration` to Error to force types everywhere, and `unsafe_method_access` / `unsafe_property_access` to Warn to surface the runtime-only failures above. Match the project's existing settings before adding a script.
