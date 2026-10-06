use bevy::prelude::*;

const PROJECTILE_SPEED: f32 = 600.0;
const HIT_RADIUS: f32 = 16.0;

#[derive(Component)]
struct Player;

#[derive(Component)]
struct Enemy;

#[derive(Component)]
struct Health(f32);

#[derive(Component)]
struct Projectile {
    damage: f32,
}

#[derive(Component)]
struct HpLabel;

#[derive(Component)]
struct KillLabel;

#[derive(Resource, Default)]
struct Kills(u32);

fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .init_resource::<Kills>()
        .add_systems(Startup, setup)
        .add_systems(
            Update,
            (
                fire_projectile,
                move_projectiles,
                apply_hits,
                despawn_dead,
                update_hp_label,
                update_kill_label,
            ),
        )
        .run();
}

fn setup(mut commands: Commands) {
    commands.spawn(Camera2d);
    commands.spawn((
        Player,
        Health(100.0),
        Sprite::from_color(Color::srgb(0.2, 0.6, 1.0), Vec2::splat(24.0)),
        Transform::from_xyz(-300.0, 0.0, 0.0),
    ));
    for i in 0..5 {
        commands.spawn((
            Enemy,
            Health(30.0),
            Sprite::from_color(Color::srgb(1.0, 0.3, 0.3), Vec2::splat(24.0)),
            Transform::from_xyz(200.0, -160.0 + 80.0 * i as f32, 0.0),
        ));
    }
    commands.spawn((
        Node {
            position_type: PositionType::Absolute,
            left: Val::Px(10.0),
            top: Val::Px(10.0),
            flex_direction: FlexDirection::Column,
            ..default()
        },
        children![
            (HpLabel, Text::new("Enemy HP: 150")),
            (KillLabel, Text::new("Kills: 0")),
        ],
    ));
}

fn fire_projectile(
    mut commands: Commands,
    keys: Res<ButtonInput<KeyCode>>,
    player: Query<&Transform, With<Player>>,
) {
    if !keys.just_pressed(KeyCode::Space) {
        return;
    }
    let Ok(player) = player.single() else { return };
    commands.spawn((
        Projectile { damage: 10.0 },
        Sprite::from_color(Color::WHITE, Vec2::splat(6.0)),
        Transform::from_translation(player.translation),
    ));
}

fn move_projectiles(time: Res<Time>, mut projectiles: Query<&mut Transform, With<Projectile>>) {
    for mut transform in &mut projectiles {
        transform.translation.x += PROJECTILE_SPEED * time.delta_secs();
    }
}

fn apply_hits(
    mut commands: Commands,
    projectiles: Query<(Entity, &Transform, &Projectile)>,
    mut enemies: Query<(&Transform, &mut Health), With<Enemy>>,
) {
    for (projectile, projectile_transform, stats) in &projectiles {
        for (enemy_transform, mut health) in &mut enemies {
            if projectile_transform
                .translation
                .distance(enemy_transform.translation)
                < HIT_RADIUS
            {
                health.0 -= stats.damage;
                commands.entity(projectile).despawn();
                break;
            }
        }
    }
}

fn despawn_dead(
    mut commands: Commands,
    mut kills: ResMut<Kills>,
    enemies: Query<(Entity, &Health), With<Enemy>>,
) {
    for (enemy, health) in &enemies {
        if health.0 <= 0.0 {
            kills.0 += 1;
            commands.entity(enemy).despawn();
        }
    }
}

fn update_hp_label(
    changed: Query<(), (With<Enemy>, Changed<Health>)>,
    enemies: Query<&Health, With<Enemy>>,
    mut label: Query<&mut Text, With<HpLabel>>,
) {
    if changed.is_empty() {
        return;
    }
    let Ok(mut text) = label.single_mut() else { return };
    let total: f32 = enemies.iter().map(|health| health.0.max(0.0)).sum();
    text.0 = format!("Enemy HP: {total}");
}

fn update_kill_label(kills: Res<Kills>, mut label: Query<&mut Text, With<KillLabel>>) {
    if !kills.is_changed() {
        return;
    }
    let Ok(mut text) = label.single_mut() else { return };
    text.0 = format!("Kills: {}", kills.0);
}
