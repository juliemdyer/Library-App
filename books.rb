require "sinatra"
require "json"
require 'pg'
require 'open-uri'
set :bind, "0.0.0.0"
# require 'net/http'
# require 'CGI'
# require 'open-uri'
# require 'rexml/document'
require 'yaml'

def get_isbn(title)
    access_key = '6Z7QHG8S'
    while (title)
      title.chomp!
      url = "http://isbndb.com/api/books.xml?access_key=" + access_key + "&index1=title&value1=" + CGI::escape(title)
      xml = REXML::Document.new(open(url).read)
      if (xml.elements["ISBNdb/BookList/BookData"])
        return xml.elements["ISBNdb/BookList/BookData"].attributes["isbn"]
      end
    end
end

def book_data()
    config = YAML::load_file "config.yml"
    conn = PG.connect( dbname: 'library', host: config["host"], user: 'postgres', password: config["password"] )
    conn.exec( "SELECT * FROM books order by title" ) do |result|
        books_array = []
        result.each do |row|
            books_array.push(row)
        end
        return books_array
    end
end

# Homepage
get("/") do
    @output = book_data()
    erb :welcome
end

# Add Book page
get("/add_book") do
    erb :add_book
end

# API call
post("/api_call") do
    api_url = request["url"]
    data = open(api_url)
    response = data
end

# Update book page
post("/update/:title/:author/:description") do
    @title = params[:title]
    @author = params[:author]
    @description = params[:description]
    erb :update
end


# Add book form submission
post("/save_book") do
    @title = params[:title]
    @author = params[:author]
    @description = params[:description]
    @cover = params[:cover]
    config = YAML::load_file "config.yml"
    conn = PG.connect( dbname: 'library', host: config["host"], user: 'postgres', password: config["password"] )
    conn.exec( "insert into books values (default, $1, $2, $3, $4)", [@title, @author, @description, @cover] )
    response = "saved"
    # redirect ("/")
end

# Update book form submission
post("/update_book/:title") do
    title = params[:title]
    new_title = params[:new_title]
    new_author = params[:new_author]
    new_content = params[:new_content]
    config = YAML::load_file "config.yml"
    conn = PG.connect( dbname: 'library', host: config["host"], user: 'postgres', password: config["password"] )
    conn.exec( "Update books set title = $1, author = $2, description = $3 where title = $4", [new_title, new_author, new_content, title] )
    redirect ("/")
end

# Delete book form submission
post("/delete/:title") do
    title = params[:title]
    config = YAML::load_file "config.yml"
    conn = PG.connect( dbname: 'library', host: config["host"], user: 'postgres', password: config["password"] )
    conn.exec( "Delete from books where title = $1", [title] )
    redirect ("/")
end
