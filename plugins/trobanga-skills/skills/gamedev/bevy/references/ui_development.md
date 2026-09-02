# Bevy UI Development Reference

## Bevy UI Hierarchy

Bevy UI uses a flexbox-like layout system:

```rust
commands
    .spawn((
        Node {
            position_type: PositionType::Absolute,
            left: Val::Px(10.0),
            top: Val::Px(10.0),
            width: Val::Px(300.0),
            padding: UiRect::all(Val::Px(10.0)),
            flex_direction: FlexDirection::Column,
            ..default()
        },
        BackgroundColor(Color::srgba(0.1, 0.1, 0.1, 0.9)),
    ))
    .with_children(|parent| {
        parent.spawn((
            Text::new("Title"),
            TextFont { font_size: 16.0, ..default() },
            TextColor(Color::WHITE),
        ));
    });
```

## UI Component Pattern

**1. Marker Components for UI Elements**
```rust
#[derive(Component)]
pub struct SpellBar;

#[derive(Component)]
pub struct HoverTooltip;

#[derive(Component)]
pub struct InspectPanel;
```

**2. Setup System (Startup)**
```rust
pub fn setup_ui(mut commands: Commands) {
    commands.spawn((
        SpellBar,
        Node { /* layout */ },
        BackgroundColor(/* color */),
    ))
    .with_children(|parent| {
        // Child elements
    });
}
```

**3. Update System (Update)**
```rust
pub fn update_ui(
    state: Res<GameState>,
    mut query: Query<&mut Text, With<SpellBar>>,
) {
    for mut text in query.iter_mut() {
        **text = format!("State: {:?}", state);
    }
}
```

## UI Best Practices

### Layout Tips

- Use `Val::Px()` for fixed sizes
- Use `Val::Percent()` for responsive layouts
- Use `flex_direction: FlexDirection::Column` for vertical stacking
- Use `flex_direction: FlexDirection::Row` for horizontal stacking
- Use `justify_content` and `align_items` for alignment

### Positioning

**Absolute positioning (HUD elements):**
```rust
Node {
    position_type: PositionType::Absolute,
    left: Val::Px(10.0),
    top: Val::Px(10.0),
    ..default()
}
```

**Centered element:**
```rust
Node {
    position_type: PositionType::Absolute,
    left: Val::Percent(50.0),
    top: Val::Percent(50.0),
    margin: UiRect {
        left: Val::Px(-150.0),  // Half of width
        top: Val::Px(-100.0),   // Half of height
        ..default()
    },
    width: Val::Px(300.0),
    height: Val::Px(200.0),
    ..default()
}
```

### Visibility Control

```rust
// Show/hide with Display
mut node: Query<&mut Node, With<Panel>>

// Hide
node.display = Display::None;

// Show
node.display = Display::Flex;
```

### Color and Styling

```rust
// Background
BackgroundColor(Color::srgba(0.1, 0.1, 0.1, 0.9))

// Border
BorderColor::all(Color::srgba(0.3, 0.6, 0.9, 1.0))

// Highlight on selection
*bg_color = BackgroundColor(Color::srgba(0.2, 0.4, 0.6, 1.0));
*border_color = BorderColor::all(Color::srgba(0.3, 0.6, 0.9, 1.0));
```

### Text Updates

```rust
// Update text content
**text = "New content".to_string();

// Or with formatting
**text = format!("Value: {:.2}", value);

// Multi-line text
**text = "Line 1\nLine 2\nLine 3".to_string();
```

## Bevy 0.18 UI Changes

### BorderRadius on Node

`BorderRadius` is now a field on `Node`, not a separate component:
```rust
// Spawning BorderRadius as a separate component does nothing
// Use the field on Node instead:
commands.spawn(Node {
    border_radius: BorderRadius::all(Val::Px(8.0)),
    ..default()
});
```

### LineHeight Component

`LineHeight` has been removed from `TextFont` and is now a separate component:
```rust
commands.spawn((
    Text::new("Hello"),
    TextFont { font_size: 16.0, ..default() },
    LineHeight::default(),
));
```

### BorderRect Changes

`BorderRect` fields changed from `left`/`right`/`top`/`bottom` to `min_inset`/`max_inset` Vec2:
```rust
// 0.18 border definition
BorderRect {
    min_inset: Vec2::splat(5.0),  // left, top
    max_inset: Vec2::splat(5.0),  // right, bottom
}
```

### Standard Widgets

Bevy 0.18 includes built-in UI widgets:
- **Popover** — tooltip-like overlays anchored to elements
- **MenuPopup** — dropdown/context menus
- **RadioButton / RadioGroup** — radio button selection groups
- **AutoDirectionalNavigation** — keyboard/gamepad UI navigation
- **IgnoreScroll** — opt individual elements out of scroll containers

### Font Variations

Variable font support and text decorations:
- Font weight variation (light, regular, bold, etc.)
- Strikethrough text decoration
- Underline text decoration
- OpenType feature configuration

### Text Picking

Non-text areas within text nodes are no longer pickable in 0.18. Only actual text content responds to picking/interaction events.
