Sequel.migration do
  up do
    create_table! :locations do
      primary_key :id
      column :longitude, :numeric
      column :latitude, :numeric
      column :horizontal_accuracy, :numeric
      column :vertical_accuracy, :numeric
      column :altitude, :numeric
      column :speed, :numeric
      column :course, :numeric
      column :timestamp, :timestamp

      column :created_at, :timestamp
      column :updated_at, :timestamp

      column :point, :geography

      index :timestamp
      spatial_index :point
    end

    create_table! :visits do
      primary_key :id
      column :longitude, :numeric
      column :latitude, :numeric
      column :horizontal_accuracy, :numeric
      column :arrival_date, :timestamp
      column :departure_date, :timestamp

      column :created_at, :timestamp
      column :updated_at, :timestamp

      column :point, :geography

      index :arrival_date
      index :departure_date
      spatial_index :point
    end
  end

  down do
    drop_table! :visits
    drop_table! :locations
  end
end
