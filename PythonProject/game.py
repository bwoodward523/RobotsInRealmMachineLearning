import pygame
import random
from particle import Particle
# ----- Game Settings -----
WIDTH = 480
HEIGHT = 600
FPS = 120
PLAYER_SPEED = 5
BULLET_SPEED = -8
MOB_SPEED_Y = 1.5  # Slower enemy movement
ENEMY_BULLET_SPEED = 5  # Speed of enemy bullets
ENEMY_SHOOT_INTERVAL = 1000  # milliseconds between shots (on average)

# Define Colors
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
RED = (255, 0, 0)
GREEN = (0, 255, 0)
BLUE = (0, 0, 255)

kill_count = 0
# Initialize pygame and create window
pygame.init()
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Simple Pygame Shmup")
clock = pygame.time.Clock()


# ----- Sprite Classes -----

class Player(pygame.sprite.Sprite):
    def __init__(self):
        pygame.sprite.Sprite.__init__(self)
        self.image = pygame.Surface((25, 35))
        self.image.fill(GREEN)
        self.rect = self.image.get_rect()
        self.rect.centerx = WIDTH / 2
        self.rect.bottom = HEIGHT - 10
        self.speedx = 0

    def update(self):
        self.speedx = 0
        keystate = pygame.key.get_pressed()
        if keystate[pygame.K_LEFT]:
            self.speedx = -PLAYER_SPEED
        if keystate[pygame.K_RIGHT]:
            self.speedx = PLAYER_SPEED
        self.rect.x += self.speedx
        # Keep player within screen boundaries
        if self.rect.right > WIDTH:
            self.rect.right = WIDTH
        if self.rect.left < 0:
            self.rect.left = 0

    def shoot(self):
        bullet = Bullet(self.rect.centerx, self.rect.top)
        all_sprites.add(bullet)
        bullets.add(bullet)


class Mob(pygame.sprite.Sprite):
    def __init__(self):
        pygame.sprite.Sprite.__init__(self)
        self.image = pygame.Surface((30, 40))
        self.image.fill(RED)
        self.rect = self.image.get_rect()
        self.rect.x = random.randrange(WIDTH - self.rect.width)
        self.rect.y = random.randrange(-100, -40)
        self.speedy = MOB_SPEED_Y
        self.speedx = random.choice([-1, 0, 1])
        self.last_shot = pygame.time.get_ticks()
        self.shoot_delay = random.randint(800, 1500)  # enemies shoot at random intervals

    def update(self):
        self.rect.y += self.speedy
        self.rect.x += self.speedx

        # Respawn if it goes off screen
        if self.rect.top > HEIGHT + 10 or self.rect.left < -25 or self.rect.right > WIDTH + 25:
            self.rect.x = random.randrange(WIDTH - self.rect.width)
            self.rect.y = random.randrange(-100, -40)
            self.speedy = MOB_SPEED_Y

        # Enemy shooting logic
        now = pygame.time.get_ticks()
        if now - self.last_shot > self.shoot_delay:
            self.shoot()
            self.last_shot = now
            self.shoot_delay = random.randint(800, 1500)  # new random delay

    def shoot(self):
        enemy_bullet = EnemyBullet(self.rect.centerx, self.rect.bottom)
        all_sprites.add(enemy_bullet)
        enemy_bullets.add(enemy_bullet)


class Bullet(pygame.sprite.Sprite):
    def __init__(self, x, y):
        pygame.sprite.Sprite.__init__(self)
        self.image = pygame.Surface((5, 10))
        self.image.fill(WHITE)
        self.rect = self.image.get_rect()
        self.rect.centerx = x
        self.rect.bottom = y
        self.speedy = BULLET_SPEED

    def update(self):
        self.rect.y += self.speedy
        # Kill if it moves off the top of the screen
        if self.rect.bottom < 0:
            self.kill()


class EnemyBullet(pygame.sprite.Sprite):
    def __init__(self, x, y):
        pygame.sprite.Sprite.__init__(self)
        self.image = pygame.Surface((5, 10))
        self.image.fill(BLUE)
        self.rect = self.image.get_rect()
        self.rect.centerx = x
        self.rect.top = y
        self.speedy = ENEMY_BULLET_SPEED

    def update(self):
        self.rect.y += self.speedy
        if self.rect.top > HEIGHT:
            self.kill()


# ----- Game Setup -----
all_sprites = pygame.sprite.Group()
mobs = pygame.sprite.Group()
bullets = pygame.sprite.Group()
enemy_bullets = pygame.sprite.Group()
player = Player()
all_sprites.add(player)

for i in range(8):  # Create 8 mobs
    m = Mob()
    all_sprites.add(m)
    mobs.add(m)

# ----- Game Loop -----
running = True
while running:
    clock.tick(FPS)

    # Process input events
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        elif event.type == pygame.KEYDOWN:
            if event.key == pygame.K_SPACE:
                player.shoot()

    # Update
    all_sprites.update()

    # Player bullet hits enemy
    hits = pygame.sprite.groupcollide(mobs, bullets, True, True)
    for hit in hits:
        # Create replacement mob
        m = Mob()
        all_sprites.add(m)
        mobs.add(m)
        kill_count += 1

        # Spawn some particles
        for i in range(random.randint(2, 15)):
            vel = (random.uniform(-2, 2), random.uniform(-2, 2))
            p = Particle(hit.rect.centerx, hit.rect.centery, color=RED, scale=0.4, lifetime=400, velocity=vel,
                         fade=True)
            all_sprites.add(p)

    # Enemy bullet hits player
    hits = pygame.sprite.spritecollide(player, enemy_bullets, True)
    if hits:
        running = False  # End game when hit

    # Enemy collides with player
    hits = pygame.sprite.spritecollide(player, mobs, False)
    if hits:
        running = False

    # Draw / render
    screen.fill(BLACK)
    all_sprites.draw(screen)

    # UI

    #DISPLAYING KILL_COUNT
    font = pygame.font.SysFont(None, 36)
    text_surface = font.render(f"Kills: {kill_count}", True, WHITE)
    screen.blit(text_surface, (10, 10))

    pygame.display.flip()

pygame.quit()
print("Final Kill Count:", kill_count)
