require 'pry'
class Dog

  attr_accessor :name, :breed, :id

  def initialize(hash, id= nil)
    @id = id
    @name = hash[:name]
    @breed = hash[:breed]
  end

  def self.create_table
    sql = <<-SQL
      CREATE TABLE dogs (
        id INTEGER PRIMARY KEY,
        name TEXT, 
        breed TEXT
      );
    SQL

    DB[:conn].execute(sql)
  end

  def self.drop_table
    sql = <<-SQL
      DROP TABLE dogs;
    SQL

    DB[:conn].execute(sql)
  end

  def save
    if self.id
      self.update
    else
      sql = <<-SQL
      INSERT INTO dogs (name, breed) 
      VALUES (?, ?);
      SQL

      DB[:conn].execute(sql, self.name, self.breed)
      #if !id
      #find last record and add the id using SET
      @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
      self
    end
  end

  def self.create(hash)
    new_dog = Dog.new(hash)
    new_dog.save
  end

  def self.new_from_db(hash)
    new_dog = Dog.new({name: hash[1], breed: hash[2]})
    new_dog.id = hash[0]
    new_dog
  end

  def self.find_by_id(num)
    sql = <<-SQL
      SELECT * FROM dogs
      WHERE id = ?
    SQL

    DB[:conn].execute(sql, num).map do |row|
      self.new_from_db(row)
    end.first
  end

  def self.find_or_create_by(hash)
    #hash at this point is {:name=>"teddy", :breed=>"cockapoo"}
    name = hash[:name]
    breed = hash[:breed]
    sql = <<-SQL
      SELECT * FROM dogs WHERE name = ? AND breed = ?
    SQL
    dog = DB[:conn].execute(sql, name, breed)
    #dog at this point is [[1, "teddy", "cockapoo"]]
    if !dog.empty?
      dog_data = dog[0]
      dog = Dog.new(hash, dog_data[0])
      #dog at this point is #<Dog:0x00007febca294f88 @breed="cockapoo", @id=1, @name="teddy">
    else
      dog = self.create(hash)
      #dog at this poing is #<Dog:0x00007fa71c1e2b00 @breed="irish setter", @id=nil, @name="teddy">
    end
    dog
    #1st time:  #<Dog:0x00007fe987adf610 @breed="cockapoo", @id=1, @name="teddy">
    #2nd time:  #<Dog:0x00007fe987baf388 @breed="cockapoo", @id=1, @name="teddy">
    #3rd time:  #<Dog:0x00007fe987cee618 @breed="irish setter", @id=nil, @name="teddy">
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT * FROM dogs WHERE name = ?
      SQL
    dog = DB[:conn].execute(sql, name)[0]
    if dog
      new_dog = self.find_by_id(dog[0])
    end
    new_dog
  end

  def update
    sql = <<-SQL
      UPDATE dogs SET name = ?,breed = ? WHERE id = ?
    SQL

    DB[:conn].execute(sql, self.name, self.breed, self.id)
  end

end