require 'yaml'

class GdshowsdatabaseUpgradeGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  @@migrations_dir = File.expand_path('../../templates', __FILE__) 
  source_root @@migrations_dir

  def initialize(a, b, c)
    super
    @song_refs = YAML.load_file(Gem.datadir('gdshowsdb') + "/song_refs.yaml")
  end

  def self.next_migration_number(path)
    Time.now.utc.strftime("%Y%m%d%H%M%S")
  end

  def create_update_migration_file
    find_changes
    
    puts "New Songs"
    puts @new_song_refs.inspect

    puts "Deleted Songs"
    puts @deleted_song_refs.inspect

    puts "Updated Songs"
    puts @updated_song_refs.inspect

    file = @@migrations_dir + "/update_migration.rb.erb"
    migration_template(file, "db/migrate/update_gdshowsdb_data.rb")

  end

  private

  def find_changes
    song_refs_values, song_refs_names = yaml_song_refs    
    song_refs_db_values, song_refs_db_names = database_song_refs
    
    add_new_song_refs(song_refs_values, song_refs_db_values)
    remove_deleted_song_refs(song_refs_values, song_refs_db_values)    
    changed_song_names(song_refs_names, song_refs_db_names)
  end

  def add_new_song_refs(song_refs_values, song_refs_db_values)
    song_refs_uuid_keys = @song_refs.invert
    new_song_ref_uuids = song_refs_values - song_refs_db_values
    new_song_ref_uuids.each do |uuid|
      new_song_ref(uuid, song_refs_uuid_keys[uuid])
    end
  end

  def remove_deleted_song_refs(song_refs_values, song_refs_db_values)
    removed_song_ref_uuids = song_refs_db_values - song_refs_values
    removed_song_ref_uuids.each do |uuid|
      remove_song_ref(uuid)
    end
  end

  def changed_song_names(song_refs_names, song_refs_db_names)
    changed_song_ref_names = song_refs_names - song_refs_db_names
    changed_song_ref_names.each do |name|
      update_song_name(@song_refs[name], name)
    end
  end

  def new_song_ref(uuid, name)
    @new_song_refs = {} unless @new_song_refs
    @new_song_refs[uuid] = name
  end

  def remove_song_ref(uuid)
    @deleted_song_refs = [] unless @deleted_song_refs
    @deleted_song_refs.push uuid
  end

  def update_song_name(uuid, name)
    @updated_song_refs = {} unless @updated_song_refs
    @updated_song_refs[uuid] = name unless @new_song_refs.has_key? uuid
  end

  def yaml_song_refs
    [@song_refs.values.sort, @song_refs.keys.sort]
  end

  def database_song_refs
    [SongRef.connection.select_values("select uuid from song_refs").sort,
     SongRef.connection.select_values("select name from song_refs").sort]
  end
end