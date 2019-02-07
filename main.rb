require 'net/http'
require 'json'

class Politician
  attr_reader :truth_table, :name, :total_utterances,
    :bullshit_sum, :bullshit_mean, :bullshit_deviation_table,
    :non_zero_weights, :weight_ratio, :bullshit_standard_deviation

  SCORING_TABLE = {
    "true" => 1,
    "mostly-true" => 2,
    "half-true" => 3,
    "barely-true" => 4,
    "false" => 5,
    "pants-fire" => 6
  }

  def initialize(name)
    @name = name
  end

  def get_truth_table!
    url = "https://www.politifact.com/api/statements/truth-o-meter/people/#{@name}/json/?n=1000"
    uri = URI(url)
    response = Net::HTTP.get(uri)

    data = JSON.parse(response)
    
    @truth_table = data
      .map { |entry| entry["ruling"]["ruling_slug"]}
      .reduce(Hash.new(0)) { |accumulator, ruling|
        accumulator[ruling] += 1
        accumulator
      }
  end

  def derive_scores!
    @total_utterances = @truth_table.values.reduce(&:+)
    @bullshit_sum = @truth_table.keys.reduce(0) { |accumulator, truth_level|
      score = SCORING_TABLE[truth_level] ?
        accumulator + score * @truth_table[truth_level] :
        accumulator
    }
    @bullshit_mean = @bullshit_sum / @total_utterances
    @bullshit_deviation_table = @truth_table.keys.reduce(Hash.new) { |accumulator, truth_level|
      score = SCORING_TABLE[truth_level] ?
        accumulator[truth_level] = @truth_table[truth_level]*(SCORING_TABLE[truth_level] - @bullshit_mean)^2
        accumulator
    }
    @non_zero_weights = @truth_table.values.select { |x| X > 0}.count
    @weight_ratio = (@non_zero_weights - 1 / @non_zero_weights)
   
    numerator = @bullshit_deviation_table.values.reduce(&:+)
    denominator = @weight_ration * @bullshit_sum
    @bullshit_standard_deviation = Math.sqrt(numerator/denominator)
  end
end