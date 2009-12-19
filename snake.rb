#!/usr/bin/ruby

require 'curses'
require 'timeout'
require 'curses'


$maxY=`stty -a | grep rows | awk '{print $5}' | sed -e 's/;//g'`.to_i
$maxX=`stty -a | grep rows | awk '{print $7}' | sed -e 's/;//g'`.to_i

class Apple
	attr_accessor :x,:y
	def initialize()
		@x=rand($maxX)
		@y=rand($maxY)
	end
	def draw
		Curses.setpos(y,x)
		Curses.addstr('O')
	end
end
$apples = []
$apples.push(Apple.new)

class SnakeParticle
	attr_accessor :x,:y
	def initialize(x,y)
		@x=x
		@y=y
	end
	def draw(character)
		Curses.setpos(y,x)
		Curses.addstr(character)
	end
end

def randomSnakeParticle
	SnakeParticle.new(rand($maxX),rand($maxY))
end

def randomDirection
	newDirection=[:right,:left,:up,:down][rand(4)]
end

class Snake
	attr :direction
	attr :particles
	def initialize
		@direction=randomDirection
		@particles=[randomSnakeParticle]
	end
	def head
		particles[0]
	end
	def update(newDirection)
		oldDirection=@direction
		oldHead=particles[0]
		newX=oldHead.x
		newY=oldHead.y
		case newDirection
			when :left
				if oldDirection==:right
					newDirection=oldDirection
				end
			when :right
				if oldDirection==:left
					newDirection=oldDirection
				end
			when :up
				if oldDirection==:down
					newDirection=oldDirection
				end
			when :down
				if oldDirection==:up
					newDirection=oldDirection
				end
		end
		@direction=newDirection
		case newDirection
			when :left
				newX=newX-1
				if newX < 0
					newX=$maxX
				end
			when :right
				newX=newX+1
				if newX > $maxX
					newX=0
				end
			when :up
				newY=newY-1
				if newY < 0
					newY=$maxY
				end
			when :down
				newY=newY+1
				if newY > $maxY
					newY=0
				end
		end
		newHead=SnakeParticle.new(newX,newY)		
		@particles.insert(0,newHead)
		eatenApple=nil
		$apples.each do |apple|
			if apple.x == newX && apple.y == newY
				eatenApple=apple
				$apples.delete(apple)
				$apples.push(Apple.new)
			end
		end
		if eatenApple==nil
			@particles.pop
		end
	end
	def valid
		x = head.x
		y = head.y
		biteCount = 0
		@particles.each do |particle|
			if particle.x == x && particle.y == y
				biteCount = biteCount + 1
			end
		end
		selfBite = (biteCount > 1)
		!selfBite
		
	end
	def draw(character)
		particles.each { |particle| particle.draw(character) }
		headCharacter=''
		case @direction 
			when :left
				headCharacter = '<'
			when :right
				headCharacter = '>'
			when :up
				headCharacter = '^'
			when :down
				headCharacter = 'V'
		end
		Curses.setpos(head.y,head.x)
		Curses.addstr(headCharacter)
	end
	def moveToApple(apple)
		newDirection=@direction
		if apple.x > head.x
			newDirection=:right
		elsif apple.x < head.x
			newDirection=:left
		elsif apple.y > head.y
			newDirection=:down
		elsif apple.y < head.y
			newDirection=:up
		end
		if rand(7)==1
			newDirection=[:right,:left,:up,:down][rand(4)]
		end
		update(newDirection)
	end
end
	
$stop=false
Curses.init_screen
Curses.stdscr.keypad(true)

$otherSnakes=[]
def addSnake
	$otherSnakes.push(Snake.new)
end

$snake=Snake.new

while !$stop do
	input=''
	newDirection=$snake.direction
	begin
	timeout(0.075) {
		input=Curses.getch
	}
	rescue TimeoutError 
		input=:timeout
	end
	case input 
		when ?q
			$stop=true
		when Curses::Key::LEFT
			newDirection=:left
		when Curses::Key::RIGHT
			newDirection=:right
		when Curses::Key::UP
			newDirection=:up
		when Curses::Key::DOWN
			newDirection=:down
	end
	$snake.update(newDirection)
	if !$snake.valid
		Curses.setpos($maxY/2.round,$maxX/2.round)
		Curses.addstr('GAME OVER '+$snake.particles.size.to_s+' points')
		Curses.refresh
		break
	end
	Curses.clear
	$apples.each { |apple| apple.draw }

	$snake.draw('X')
	
	$otherSnakes.each do |snake|
		snake.moveToApple($apples[0])
		snake.draw('*')
		if !snake.valid
			$otherSnakes.delete(snake)
		end
	end
	
	if rand(1000)==1 
		addSnake
	end
	
	Curses.setpos(0,0)
	Curses.addstr('')
	Curses.refresh
end



	
