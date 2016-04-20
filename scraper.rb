require "open-uri"
require "nokogiri"
require "json"
require "pry"

class Monster
  attr_accessor :name, :monster_tags, :attack, :damage, :attack_tags,
    :hp, :armor, :special_qualities, :description, :instinct, :moves

  def initialize(attrs = {})
    self.attributes = attrs
  end

  def attributes=(attrs)
    attrs.each do |key, value|
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

class MonsterListingParser
  module Adapter
    class OneParagraph
      def self.parse(paragraphs)
        {
          description: paragraphs[0].content
        }
      end
    end

    class TwoParagraphs
      def self.parse(paragraphs)
        {
          monster_tags: paragraphs[0].content,
          description: paragraphs[1].content
        }
      end
    end

    class ThreeParagraphs
      def self.parse(paragraphs)
        {
          monster_tags: paragraphs[0].content,
          special_qualities: paragraphs[1].content,
          description: paragraphs[2].content
        }
      end
    end

    class AllTheParagraphs
      def self.parse(paragraphs)
        {}.tap do |attrs|
          attrs[:monster_tags] = paragraphs[0].content

          stats = paragraphs[1].content.split(";")
          attrs[:attack] = stats[0].split("(")[0].strip
          attrs[:damage] = stats[0].split("(")[1].gsub(")", "").gsub("damage", "").strip
          attrs[:hp] = stats[1].gsub("HP", "").strip
          attrs[:armor] = stats[2].gsub("Armor", "").strip
          attrs[:attack_tags ] = paragraphs[2].content

          if paragraphs[3].content =~ /Qualities/
            attrs[:special_qualities] = paragraphs[3].content.split(":")[1].strip
            attrs[:description] = paragraphs[4].content.split("Instinct: ")[0]
            attrs[:instinct] = paragraphs[4].content.split("Instinct: ")[1]
          else
            attrs[:description] = paragraphs[3].content.split("Instinct: ")[0]
            attrs[:instinct] = paragraphs[3].content.split("Instinct: ")[1]
          end
        end
      end
    end
  end

  def initialize(div)
    @attrs = {}
    @div = div
    select_adapter
  end

  # h4 = name
  # p1 = monster tags
  # p2 = attack
  # p3 = attack tags
  # p4 = Special Qualities || Description
  # p5 = (if present) description
  # In description, after the <i></i>: Instinct.
  def parse
    @attrs[:name] = @div.css("h4")[0].content
    @attrs[:moves] = @div.css("li").map(&:content)

    @attrs.merge(self.adapter.parse(paragraphs))
  end

  def adapter
    return @adapter if @adapter
    self.adapter = "AllTheParagraphs"
    @adapter
  end

  def adapter=(adapter)
    @adapter = MonsterListingParser::Adapter.const_get(adapter)
  end

  private

  def select_adapter
    self.adapter = if paragraphs.size == 1
      "OneParagraph"
    elsif paragraphs.size == 2
      "TwoParagraphs"
    elsif paragraphs.size == 3
      "ThreeParagraphs"
    else
      "AllTheParagraphs"
    end
  end

  def paragraphs
    @paragraphs ||= @div.css("p")
  end
end

html = open("monsters.html")
page = Nokogiri::HTML(html.read)
page.encoding = "utf-8"
divs = page.css("div")
monsters = divs.map do |div|
  monster = Monster.new
  parser = MonsterListingParser.new(div)
  monster.attributes = parser.parse

  puts "\n----------"
  puts monster.to_s

  monster
end

File.open("monsters.json", "w:UTF-8") do |file|
  monsters.each do |monster|
    file.write(monster.to_h.to_json + "\n")
  end
end
