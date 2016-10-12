module Bot
  module Database
    # A Game
    class Game < Sequel::Model
      many_to_one :owner,  class: '::Bot::Database::Player'
      many_to_one :czar,   class: '::Bot::Database::Player'
      many_to_one :winner, class: '::Bot::Database::Player'
      one_to_many :players
      one_to_many :rounds
      one_to_many :expansion_pools

      # Returns the game owned by the associated
      # Discord ID
      def self.owner(id)
        all.find { |g| g.owner.discord_id == id }
      end

      # Clean up before destruction
      def before_destroy
        delete_channels
      end

      # Fetch channel from bot cache
      def text_channel
        BOT.channel(text_channel_id)
      end

      # Fetch channel from bot cache
      def voice_channel
        BOT.channel(voice_channel_id)
      end

      # Deletes Discord channels for the game
      def delete_channels
        text_channel.delete
        voice_channel.delete
      end

      # Starts a game
      def start!
        return if started

        # Shuffle deck
        answers = Answer.freeze.all.shuffle

        # Distribute cards
        answers.each_with_index do |a, i|
          players.at(i % players.count)
                 .add_player_card(PlayerCard.new(answer: a))
        end

        # Create the first round
        add_round(Round.create)
      end

      # End a game. Destroys the game
      # if it has no decided winner, otherwise
      # keep the Game for history and just clean
      # up the channels.
      def end!
        if winner.nil?
          destroy
        else
          delete_channels
        end
      end

      # Returns the Expansions currently included in the game
      def expansions
        expansion_pools.collext(&:expansion)
      end

      # Returns a flattened dataset of questions available
      # in the current game's expansion pools
      def questions
        expansions.map(&:questions).flatten
      end

      # Returns a flattened dataset of answers available
      # in the current game's expansion pools
      def answers
        expansions.map(&:answers).flatten
      end
    end
  end
end
