require "open-uri"
require "nokogiri"
require "json"
require "pry"

class Monster
  attr_accessor :name, :monster_tags, :attack, :damage, :attack_tags,
    :hp, :armor, :special_qualities, :description, :instinct, :moves

  def initialize(attributes = {})
    attributes.each do |key, value|
      self.public_send("#{key}=", value)
    end
  end

  def to_s
    "Name: #{name}\n" \
    "Monster Tags: #{monster_tags}\n" \
    "Attack: #{attack}\n" \
    "Damage: #{damage}\n" \
    "Attack Tags: #{attack_tags}\n" \
    "HP: #{hp}\n" \
    "Armor: #{armor}\n" \
    "Special Qualities: #{special_qualities}\n" \
    "Description: #{description}\n" \
    "Instinct: #{instinct}\n" \
    "Moves: #{moves}"
  end

  def to_h
    {
      name: name,
      monster_tags: monster_tags,
      attack: attack,
      damage: damage,
      attack_tags: attack_tags,
      hp: hp,
      armor: armor,
      special_qualities: special_qualities,
      description: description,
      instinct: instinct,
      moves: moves
    }
  end
end

# h4 = name
# p1 = monster tags
# p2 = attack
# p3 = attack tags
# p4 = Special Qualities || Description
# p5 = (if present) description
# In description, after the <i></i>: Instinct.

html = open("monsters.html")
page = Nokogiri::HTML(html.read)
page.encoding = "utf-8"
divs = page.css("div")
monsters = divs.map do |div|
  monster = Monster.new
  monster.name = div.css("h4")[0].content
  paragraphs = div.css("p")

  # Some weirdness in paragraphs for certain monsters
  if paragraphs.size == 1
    monster.description = paragraphs[0].content
  elsif paragraphs.size == 2
    monster.monster_tags = paragraphs[0].content
    monster.description = paragraphs[1].content
  elsif paragraphs.size == 3
    monster.monster_tags = paragraphs[0].content
    monster.special_qualities = paragraphs[1].content
    monster.description = paragraphs[2].content
  else
    monster.monster_tags = paragraphs[0].content

    stats = paragraphs[1].content.split(";")
    monster.attack = stats[0].split("(")[0].strip
    monster.damage = stats[0].split("(")[1].gsub(")", "").gsub("damage", "").strip
    monster.hp = stats[1].gsub("HP", "").strip
    monster.armor = stats[2].gsub("Armor", "").strip
    monster.attack_tags = paragraphs[2].content

    if paragraphs[3].content =~ /Qualities/
      monster.special_qualities = paragraphs[3].content.split(":")[1].strip
      monster.description = paragraphs[4].content.split("Instinct: ")[0]
      monster.instinct = paragraphs[4].content.split("Instinct: ")[1]
    else
      monster.description = paragraphs[3].content.split("Instinct: ")[0]
      monster.instinct = paragraphs[3].content.split("Instinct: ")[1]
    end
    monster.moves = div.css("li").map(&:content)

  end

  puts "\n----------"
  puts monster.to_s

  monster
end

File.open("monsters.json", "w:UTF-8") do |file|
  monsters.each do |monster|
    file.write(monster.to_h.to_json + "\n")
  end
end
