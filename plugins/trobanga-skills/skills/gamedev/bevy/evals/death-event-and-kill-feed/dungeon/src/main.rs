use bevy::prelude::*;

const PLAYER_SPEED: f32 = 220.0;
const SWORD_REACH: f32 = 40.0;
const SWORD_DAMAGE: f32 = 25.0;

#[derive(Component)]
struct Player;

#[derive(Component)]
struct Enemy;

#[derive(Component)]
struct Health(f32);

#[derive(Component)]
struct KillLabel;

fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_systems(Startup, setup)
        .add_systems(Update, (move_player, sword_attack).chain())
        .run();
}

fn setup(mut commands: Commands) {
    commands.spawn(Camera2d);
    commands.spawn((
        Player,
        Health(100.0),
        Sprite::from_color(Color::srgb(0.2, 0.6, 1.0), Vec2::splat(24.0)),
        Transform::default(),
    ));
    for i in 0..6 {
        let angle = i as f32 * std::f32::consts::TAU / 6.0;
        commands.spawn((
            Enemy,
            Health(50.0),
            Sprite::from_color(Color::srgb(1.0, 0.3, 0.3), Vec2::splat(24.0)),
            Transform::from_xyz(150.0 * angle.cos(), 150.0 * angle.sin(), 0.0),
        ));
    }
    commands.spawn((
        KillLabel,
        Text::new("Kills: 0"),
        Node {
            position_type: PositionType::Absolute,
            left: Val::Px(10.0),
            top: Val::Px(10.0),
            ..default()
        },
    ));
}

fn move_player(
    keys: Res<ButtonInput<KeyCode>>,
    time: Res<Time>,
    mut players: Query<&mut Transform, With<Player>>,
) {
    let mut direction = Vec2::ZERO;
    if keys.pressed(KeyCode::KeyW) {
        direction.y += 1.0;
    }
    if keys.pressed(KeyCode::KeyS) {
        direction.y -= 1.0;
    }
    if keys.pressed(KeyCode::KeyA) {
        direction.x -= 1.0;
    }
    if keys.pressed(KeyCode::KeyD) {
        direction.x += 1.0;
    }
    let step = direction.normalize_or_zero() * PLAYER_SPEED * time.delta_secs();
    for mut transform in &mut players {
        transform.translation += step.extend(0.0);
    }
}

fn sword_attack(
    keys: Res<ButtonInput<KeyCode>>,
    players: Query<&Transform, With<Player>>,
    mut enemies: Query<(&Transform, &mut Health), (With<Enemy>, Without<Player>)>,
) {
    if !keys.just_pressed(KeyCode::KeyJ) {
        return;
    }
    for player in &players {
        for (enemy, mut health) in &mut enemies {
            if enemy.translation.distance(player.translation) < SWORD_REACH {
                health.0 -= SWORD_DAMAGE;
            }
        }
    }
}
