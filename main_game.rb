#!/usr/bin/env ruby

require 'rubygems'
require 'gosu'
require 'pp'


class GameWindow < Gosu::Window

  attr_accessor :bullets, :stars
  
  def initialize
    super 640, 480, false
    self.caption = "Gosu Tutorial Game"
    @background_image = Gosu::Image.new(self, "stars_bg_1.gif", true)
    @player = Player.new(self)
    @player.warp(320, 240)
    @star_anim = Gosu::Image::load_tiles(self, "bullet.jpg", 25, 25, false)
    @stars = Array.new
    @normal_font = Gosu::Font.new(self, Gosu::default_font_name, 20)
    @large_font = Gosu::Font.new(self, Gosu::default_font_name, 10)
    @bullets = []
    @game_ended = false
    @ended = false
  end

  def update
    if button_down? Gosu::KbLeft or button_down? Gosu::KbA then
      @player.turn_left
    end
    if button_down? Gosu::KbRight or button_down? Gosu::KbD then
      @player.turn_right
    end
    if button_down? Gosu::KbUp or button_down? Gosu::KbW then
      @player.accelerate_forwards(0.25)
    end
    if button_down? Gosu::KbDown or button_down? Gosu::KbS then
      @player.accelerate_backwards(0.25)
    end 
    if button_down?(Gosu::KbSpace) and !@pressed
      @pressed=true
      @bullets << @player.shoot(self)
    elsif not button_down?(Gosu::KbSpace)
      @pressed=nil
    end

    @player.move
    @player.collect_stars(@stars, self)
    @player.collide(self)

    if rand(100) < 1 and @stars.size < 15 then
      @stars.push(Star.new(@star_anim))
    end
  end

  def draw
    x_factor = self.width.to_f/@background_image.width.to_f
    y_factor = self.height.to_f/@background_image.height.to_f
    @background_image.draw(0, 0, 0, factor_x = x_factor, factor_y = y_factor)
    @player.draw
    @stars.each { |star| star.draw }
    @normal_font.draw("Score: #{@player.score}", 10, 10, ZOrder::UI, 1.0, 1.0, 0xffffff00)
    @bullets.each do |bullet|
      bullet.update
      bullet.draw
    end
    if @game_ended
      if @ended == true
        sleep(2)
        button_down(Gosu::KbEscape)
      end
      @ended = true
      @game_ended = true
      @large_font.draw("YOU LOSE!", 210, 180, ZOrder::UI, 5.0, 5.0, 0xffffff00)
    end
  end
  
   def button_down(id)
    if id == Gosu::KbEscape 
      close
    end
  end
  
  def end_game
    @game_ended = true
  end
end

class Bullet

  attr_reader :bullet_angle, :x, :y

  def initialize(window, angle)
    @image = Gosu::Image.new(window, "bullet.gif", false)
    @x = @y = @vel_x = @vel_y = 0.0
    @beep = Gosu::Sample.new(window, "macossounds/macossounds/WAV/Boing.wav")
    @beep.play
    @bullet_angle = angle
  end
  
  def warp(x, y)
    @x, @y = x, y
  end
  
  def accelerate
    @vel_x += Gosu::offset_x(@bullet_angle + 90, 0.45)
    @vel_y += Gosu::offset_y(@bullet_angle + 90, 0.45)
  end
  
   def move
    @x += @vel_x
    @y += @vel_y
    @x %= 640
    @y %= 480

    @vel_x *= 0.95
    @vel_y *= 0.95
  end
  
  def update
    accelerate
    move
  end
  
  def draw
    @image.draw_rot(@x, @y, 1, 0.0)
  end
  
end

class Player

  attr_reader :score, :angle
  
  def initialize(window)
    @image = Gosu::Image.new(window, "spaceship_right_closed.gif", false)
    @beep = Gosu::Sample.new(window, "macossounds/macossounds/WAV/Logjam.wav")
    @x = @y = @vel_x = @vel_y = @angle = 0.0
    @score = 0
  end

  def warp(x, y)
    @x, @y = x, y
  end

  def turn_left
    @angle -= 4.5
  end

  def turn_right
    @angle += 4.5
  end
  
  def shoot(window)
    bullet = Bullet.new(window, @angle)
    bullet.warp(@x, @y)
    bullet
  end

  def accelerate_forwards(acceleration)
    @vel_x += Gosu::offset_x(@angle + 90, acceleration)
    @vel_y += Gosu::offset_y(@angle + 90, acceleration)
  end
  
  def accelerate_backwards(acceleration)
    @vel_x -= Gosu::offset_x(@angle + 90, acceleration)
    @vel_y -= Gosu::offset_y(@angle + 90, acceleration)
  end

  def move
    @x += @vel_x
    @y += @vel_y
    @x %= 640
    @y %= 480

    @vel_x *= 0.95
    @vel_y *= 0.95
  end

  def draw
    @image.draw_rot(@x, @y, 1, @angle)
  end
  
  def collide(window)
    window.stars.each do |star|
      if Gosu::distance(@x, @y, star.x, star.y) < 25
        window.end_game
      end
    end
  end
  
  def collect_stars(stars, window)
    stars.reject! do |star|
      bullet_near_star = false
      window.bullets.each do |bullet|
        if Gosu::distance(bullet.x, bullet.y, star.x, star.y) < 10
          bullet_near_star = true
          window.bullets[(window.bullets.index(bullet)) - 1] = nil
          window.bullets.compact!
        end
      end
      if bullet_near_star then
        @score += 10
        @beep.play
        true
      else
        false
      end
    end
  end
  
end

module ZOrder
  Background, Stars, Player, UI = *0..3
end

class Star
  attr_reader :x, :y

  def initialize(animation)
    @animation = animation
    @color = Gosu::Color.new(0xff000000)
    @color.red = rand(256 - 40) + 40
    @color.green = rand(256 - 40) + 40
    @color.blue = rand(256 - 40) + 40
    @x = rand * 640
    @y = rand * 480
  end

  def draw  
    img = @animation[Gosu::milliseconds / 100 % @animation.size];
    img.draw(@x - img.width / 2.0, @y - img.height / 2.0,
        ZOrder::Stars, 1, 1, @color, :add)
  end
  
 # def shot_at
  
 # end
  
end

window = GameWindow.new

window.show
