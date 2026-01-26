import pygame
WHITE = (255, 255, 255)
class Particle(pygame.sprite.Sprite):
    def __init__(self, x, y, color=WHITE, scale=1.0, lifetime=1000, velocity=(0, 0), fade=False):
        super().__init__()
        self.base_image = pygame.Surface((int(10 * scale), int(10 * scale)), pygame.SRCALPHA)
        pygame.draw.circle(self.base_image, color, (self.base_image.get_width() // 2, self.base_image.get_height() // 2), int(5 * scale))
        # pygame.draw.rect(self.base_image, color, (0, 0, int(10 * scale), int(10 * scale)))
        self.image = self.base_image.copy()
        self.rect = self.image.get_rect(center=(x, y))

        # Motion
        self.vel_x, self.vel_y = velocity

        # Timing
        self.lifetime = lifetime
        self.spawn_time = pygame.time.get_ticks()

        # Fade settings
        self.fade = fade
        self.alpha = 255

    def update(self):
        # Move the particle
        self.rect.x += self.vel_x
        self.rect.y += self.vel_y

        self.vel_x = self.vel_x * .99
        self.vel_y = self.vel_y * .99

        # Lifetime handling
        elapsed = pygame.time.get_ticks() - self.spawn_time
        if elapsed >= self.lifetime:
            self.kill()
            return

        # Fade effect
        if self.fade:
            remaining = self.lifetime - elapsed
            fade_time = self.lifetime * 0.3  # last 30% of life fades out
            if remaining < fade_time:
                fade_ratio = remaining / fade_time
                self.alpha = int(255 * fade_ratio)
                self.image = self.base_image.copy()
                self.image.set_alpha(self.alpha)
