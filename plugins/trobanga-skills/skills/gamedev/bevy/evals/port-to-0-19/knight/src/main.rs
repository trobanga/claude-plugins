use bevy::prelude::*;
use bevy::scene::SceneInstanceReady;

#[derive(Component)]
struct Player;

#[derive(Component)]
struct Health(f32);

#[derive(Component)]
struct HpText;

#[derive(Component)]
struct Inventory;

#[derive(Event)]
struct DamageTaken {
    amount: f32,
}

fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .insert_resource(AmbientLight {
            color: Color::WHITE,
            brightness: 400.0,
            ..default()
        })
        .add_event::<DamageTaken>()
        .add_observer(on_player_added)
        .add_systems(Startup, setup)
        .add_systems(
            Update,
            (
                take_lava_damage,
                apply_damage,
                update_hp_text,
                draw_bounds,
                reset_inventory,
            )
                .chain(),
        )
        .run();
}

fn setup(mut commands: Commands, asset_server: Res<AssetServer>) {
    commands.spawn((
        Camera3d::default(),
        Transform::from_xyz(0.0, 4.0, 8.0).looking_at(Vec3::ZERO, Vec3::Y),
    ));
    commands.spawn((
        DirectionalLight::default(),
        Transform::from_xyz(3.0, 8.0, 5.0).looking_at(Vec3::ZERO, Vec3::Y),
    ));
    commands
        .spawn((
            SceneRoot(asset_server.load(GltfAssetLabel::Scene(0).from_asset("models/knight.glb"))),
            Transform::default(),
            Player,
            Health(100.0),
        ))
        .observe(on_knight_ready);
    commands.spawn((Inventory, Transform::default())).with_children(|inventory| {
        inventory.spawn(Name::new("Sword"));
        inventory.spawn(Name::new("Potion"));
    });
    commands.spawn((
        HpText,
        Text::new("HP: 100"),
        TextFont {
            font_size: 24.0,
            ..default()
        },
        Node {
            position_type: PositionType::Absolute,
            left: Val::Px(12.0),
            top: Val::Px(12.0),
            ..default()
        },
    ));
}

fn on_player_added(trigger: Trigger<OnAdd, Player>, mut commands: Commands) {
    commands.entity(trigger.target()).insert(Name::new("Knight"));
}

fn on_knight_ready(trigger: Trigger<SceneInstanceReady>, children: Query<&Children>) {
    let count = children.iter_descendants(trigger.target()).count();
    info!("knight scene ready with {count} entities");
}

fn take_lava_damage(
    player: Query<&Transform, With<Player>>,
    mut damage: EventWriter<DamageTaken>,
) {
    if let Ok(transform) = player.get_single() {
        if transform.translation.y < 0.0 {
            damage.send(DamageTaken { amount: 1.0 });
        }
    }
}

fn apply_damage(
    mut events: EventReader<DamageTaken>,
    mut player: Query<&mut Health, With<Player>>,
) {
    let Ok(mut health) = player.get_single_mut() else { return };
    for event in events.read() {
        health.0 -= event.amount;
    }
}

fn update_hp_text(
    player: Query<&Health, (With<Player>, Changed<Health>)>,
    mut text: Query<&mut Text, With<HpText>>,
) {
    let (Ok(health), Ok(mut text)) = (player.get_single(), text.get_single_mut()) else {
        return;
    };
    text.0 = format!("HP: {:.0}", health.0);
}

fn draw_bounds(mut gizmos: Gizmos) {
    gizmos.cuboid(
        Transform::from_scale(Vec3::splat(10.0)),
        Color::srgb(1.0, 0.5, 0.0),
    );
}

fn reset_inventory(
    keys: Res<ButtonInput<KeyCode>>,
    mut commands: Commands,
    inventory: Query<Entity, With<Inventory>>,
) {
    if keys.just_pressed(KeyCode::KeyR) {
        for entity in &inventory {
            commands.entity(entity).clear_children();
        }
    }
}
