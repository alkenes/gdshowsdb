module Gdshowsdb
  class SongYAMLParser
    def initialize(shows)
      @shows = shows
    end

    def parse      
      parsed = []
      @shows.each do |key, value|
        sets = value[:sets]
        sets.each do |set|
          songs = set[:songs]
          songs.each_with_index do |song, i|
            parsed << song.merge({position: i, show_set_uuid: set[:uuid]})
          end if songs          
        end if sets       
      end
      parsed
    end
  end
end