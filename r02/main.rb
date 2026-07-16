h, w, sy, sx, n = gets.split.map(&:to_i)
grid = (1..h).map { gets.chomp.chars }

Direction = Struct.new(:compass) do
  COMPASS_INDEX = {
    'N' => 0,
    'W' => 1,
    'S' => 2,
    'E' => 3,
  }
  COMPASS_SIZE = 4
  TURN_OFFSET = {
    'L' => 1,
    'R' => 3,
  }
  DELTA = [
    [0, -1],
    [-1, 0],
    [0, 1],
    [1, 0],
  ]

  def turn(d)
    next_compass = (compass + TURN_OFFSET[d]) % COMPASS_SIZE
    self.class.new(next_compass)
  end

  def delta
    DELTA[compass]
  end

  def self.from_compass(compass)
    self.new(COMPASS_INDEX[compass])
  end
end

Point = Struct.new(:x, :y) do
  def move(direction)
    dx, dy = direction.delta
    self.class.new(x + dx, y + dy)
  end

  def to_s
    "#{y} #{x}"
  end
end

class Grid
  def initialize(grid)
    @grid = grid
    @height = grid.size
    @width = grid&.first.size || 0
  end

  def include?(point)
    (0...@width).include?(point.x) && (0...@height).include?(point.y)
  end

  def empty?(point)
    @grid[point.y][point.x] == '.'
  end
end

@direction = Direction.from_compass('N')
@point = Point.new(sx, sy)
@grid = Grid.new(grid)

def walkable?(d)
  direction = @direction.turn(d)
  next_point = @point.move(direction)
  @grid.include?(next_point) && @grid.empty?(next_point)
end

def walk!(d)
  @direction = @direction.turn(d)
  @point = @point.move(@direction)
end

n.times do
  d = gets.chomp
  if walkable?(d)
    walk!(d)
    puts @point
  else
    puts 'Stop'
    break
  end
end
