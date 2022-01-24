module Transform
  def swap_character(full_name, new_state)
    first_name, surname = full_name.split(' ')
    text.gsub!("#{full_name}", new_state)
    text.gsub!("#{first_name}\r\n#{surname}", new_state)
    text.gsub!("#{first_name}", new_state)
    text.gsub!("#{surname}", "#{new_state.split.last}")
  end

  new_states = ['boneless chud', 'the flatulent porpoise', 'beached and bloated beluga', 'friendless manatee', 'barely mammalian embarrassment']
  

  def swap_character_with_randomization(full_name, new_state)
    text.split("\r\n").map do |line|
      name_forms = []
      
      line.gsub!
  end
end

class Classic
  include Transform

  attr_accessor :text
  def initialize(text)
    @text = text
  end
end


great_gatsby = Classic.new(File.read("data/great_gatsby.txt"))
new_text = great_gatsby.swap_character('Tom Buchanan', 'The Flatulent Porpoise')
File.write("new_great_gatsby.txt", new_text)

