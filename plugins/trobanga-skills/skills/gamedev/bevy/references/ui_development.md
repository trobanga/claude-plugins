# Bevy UI

Bevy UI is a flexbox (and grid) layout over entities: every UI entity has a `Node`, styled by sibling components (`BackgroundColor`, `BorderColor`, `Text`, `TextFont`, `TextColor`). The [UI examples](https://github.com/bevyengine/bevy/tree/v0.19.1/examples/ui) cover most layouts.

## Spawn once, update by marker

Spawn the tree in a `Startup` (or `OnEnter`) system with a marker on every node you will update; update it in `Update`, filtered by the marker.

```rust
#[derive(Component)]
struct HealthBar;

fn setup_hud(mut commands: Commands) {
    commands.spawn((
        Node {
            position_type: PositionType::Absolute,
            left: Val::Px(10.0),
            top: Val::Px(10.0),
            width: Val::Px(200.0),
            padding: UiRect::all(Val::Px(4.0)),
            flex_direction: FlexDirection::Column,
            border: UiRect::all(Val::Px(2.0)),
            border_radius: BorderRadius::all(Val::Px(6.0)),
            ..default()
        },
        BackgroundColor(Color::srgba(0.1, 0.1, 0.1, 0.9)),
        BorderColor::all(Color::WHITE),
        children![
            (
                Text::new("HP"),
                TextFont { font_size: FontSize::Px(16.0), ..default() },
                TextColor(Color::WHITE),
            ),
            (
                HealthBar,
                Node { width: Val::Percent(100.0), height: Val::Px(12.0), ..default() },
                BackgroundColor(Color::srgb(0.8, 0.2, 0.2)),
            ),
        ],
    ));
}

fn update_health_bar(
    player: Query<&Health, (With<Player>, Changed<Health>)>,
    mut bar: Query<&mut Node, With<HealthBar>>,
) {
    let (Ok(health), Ok(mut node)) = (player.single(), bar.single_mut()) else { return };
    node.width = Val::Percent(health.fraction() * 100.0);
}
```

Use `with_children(|parent| { parent.spawn(..); })` instead of `children![]` when the number of children is computed at runtime.

## Layout

- Size and position with `Val::Px`, `Val::Percent`, `Val::Vw`/`Vh`, or `Val::Auto`.
- Stack with `flex_direction` (`Row` or `Column`); align with `justify_content` (main axis) and `align_items` (cross axis).
- Center a panel: give a full-screen parent `width: Val::Percent(100.0)`, `height: Val::Percent(100.0)`, `justify_content: JustifyContent::Center`, `align_items: AlignItems::Center`.
- HUD elements: `position_type: PositionType::Absolute` with `left`/`top`/`right`/`bottom`.
- Hide with `node.display = Display::None` (removes it from layout) or `Visibility::Hidden` (keeps its space).

## Text

- Replace content with `text.0 = format!("Score: {score}")` on a `Query<&mut Text, With<ScoreLabel>>`.
- Line spacing is the `bevy::text::LineHeight` component (`LineHeight::Px(20.0)` or `LineHeight::RelativeToFont(1.2)`; not in the prelude), not a `TextFont` field.
- A custom font: `font: asset_server.load("fonts/FiraSans-Bold.ttf").into()`.

## Interaction

`Button` plus the `Interaction` component gives hover/press state; query `(&Interaction, &mut BackgroundColor), Changed<Interaction>` to restyle. For click handling with bubbling, observe picking events on the entity: `.observe(|click: On<Pointer<Click>>| { .. })`.
