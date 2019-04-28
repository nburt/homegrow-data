# homegrow-data
Sinatra app to store and serve climate data from mongo db

### Dependencies
* Install mongo db with homebrew:
    * `brew tap mongodb/brew`
    * `brew install mongodb-community`
    * `brew services start mongodb-community`
    
### Development
* Install Ruby dependencies: `bundle install`
* `bundle exec rackup -p 9292 config.ru` to start the server