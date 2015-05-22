include Mongo

# Production environment will have the MONGOLAB_URI and related variables set.
DEFAULT_MONGODB_DB_NAME = "pickeez"
set :mongodb_db_name, ENV["MONGOLAB_DB_NAME"] || DEFAULT_MONGODB_DB_NAME

DEFAULT_MONGODB_URI = "mongodb://localhost:27017/#{settings.mongodb_db_name}"
set :mongodb_uri,     ENV["MONGOLAB_URI"]     || DEFAULT_MONGODB_URI

# Instantiate and connect to the production MongoLab database if production, or
# a local instance if development.
$mongo = CONN = MongoClient.from_uri(settings.mongodb_uri, {pool_size: 10}).db(settings.mongodb_db_name)
puts "Running against MongoDB: #{settings.mongodb_uri} db:#{settings.mongodb_db_name}"


# Custom methods to make dealing with Mongo object ids easier.
# Some ruby/mongo hacking here. 
class Mongo::Collection

	#get/find_by/find_one('id123')
	#get/find_by/find_one({email: 'bob@gmail.com'})
	#get/find_by/find_one('bob@gmail.com', 'email')
	def find_one(params, field = :_id)		
		return self.find(params).first if params.is_a? Hash

		find_one((field.to_s) => params)
	end
	alias_method :find_by, :find_one
  alias_method :get, :find_one

  def project(params, fields = [])
  	find(params, {fields: fields}).first
  end

	def find_all(params = {})
		self.find(params).to_a
	end
	alias_method :all, :find_all

	def add(doc)
		doc[:_id] ||= nice_id
		doc[:created_at] = Time.now
		self.insert(doc)
		doc.indiff
	end

	def first
		self.all[0]
	end

	def last 
		all = self.all
		all[all.size-1]
	end

	def one
		all = self.all
		all[rand(all.size)]
	end
	alias_method :any, :one

	def update_id(_id, fields, opts = {})
		#opts can be e.g. { :upsert => true }
		fields.updated_at = Time.now
		res = self.update({_id: _id}, {'$set' => fields}, opts)		
		{_id: _id}.merge(res).indiff
	end

	def exists?(val, field = :_id)
		self.find({field.to_s => val}, {fields: [:_id]}).limit(1).count > 0
	end

end
