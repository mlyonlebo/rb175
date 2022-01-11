=begin
knight at b8
can move to: a6, c6

knight at d5
can move:
left/right one, up/down two: c7, e7; c3, e3
left/right two, up/down one b6, f6; b4, f4; 

given a square (i.e. d5)
calculate the possible moves
  
given these possible moves, calculate the possible moves until the square is reached

=end

def x_one_y_two(square)
  moves = []
  moves << (square[0].ord + 1).chr + (square[1].to_i + 2).to_s
  moves << (square[0].ord + 1).chr + (square[1].to_i - 2).to_s
  moves << (square[0].ord - 1).chr + (square[1].to_i + 2).to_s
  moves << (square[0].ord - 1).chr + (square[1].to_i - 2).to_s
  moves
end

def x_two_y_one(square)
  moves = []
  moves << (square[0].ord + 2).chr + (square[1].to_i + 1).to_s
  moves << (square[0].ord + 2).chr + (square[1].to_i - 1).to_s
  moves << (square[0].ord - 2).chr + (square[1].to_i + 1).to_s
  moves << (square[0].ord - 2).chr + (square[1].to_i - 1).to_s
  moves
end

def possible_moves(squares)
  result = []
  squares.each do |square|
    moves = (x_one_y_two(square) + x_two_y_one(square)).select do |move|
      ('a'..'h').include?(move[0]) && (move[1].to_i >= 1 && move[1].to_i <=8)
    end
    result += moves
  end
  result  
end

def knight(start, finish)
  start = [start]
  counter = 1
  loop do 
    moves = possible_moves(start)
    break if moves.include?(finish)
    start = moves
    counter += 1
  end
  counter
end

p knight('a1', 'f4')

