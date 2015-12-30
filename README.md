# Serially

[![Build Status](https://circleci.com/gh/mikemarsian/serially.svg?&style=shield&circle-token=93a8f2925ebdd64032108118ef6e17eb3848d767)](https://circleci.com/gh/mikemarsian/serially)
[![Code Climate](https://codeclimate.com/github/mikemarsian/serially/badges/gpa.svg)](https://codeclimate.com/github/mikemarsian/serially)

Have you ever had a class that required a series of background tasks to run serially, strictly one after another? Than Serially is for you.
All background jobs are scheduled using resque in a queue called `serially`, and Serially makes sure that for every instance of your class, only one task runs at a time.
Different instances of the same class do not interfere with each other and their tasks can run in parallel.
Serially works for both plain ruby classes and ActiveRecord models. In case of the latter, all task runs results are written to `serially_tasks` table which you can interrogate pragmatically using `Serially::TaskRun` model.

See [this rails demo app][1] that showcases how Serially gem can be used.

Note: this gem is in active development and currently is not intended to run in production.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'serially'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install serially

## Optional ActiveRecord Setup

If you use ActiveRecord, you can generate a migration that creates `serially_task_runs` table, which would be used to write the results of all your task runs.

    $ rails generate serially:install
    $ rake db:migrate

## Usage
```ruby
class Post < ActiveRecord::Base
     include Serially

     serially do
        task :draft
        task :review
        task :publish
        task :promote
     end

     def draft
        puts "Post #{self.id} drafted"
        true
     end

     def review
        puts "Post #{self.id} reviewed by staff"
        [true, 'reviewed by staff']
     end

     def publish
        puts "Post #{self.id} not published - bibliography is missing"
        [false, 'bibliography is missing']
     end

     def promote
        puts "Post #{self.id} promoted"
        true
     end
   end
```

After creating a Post, you can run `post.serially.start!` to schedule your Post tasks to run serially. They will run one after the other in the scope of the same `Serially::Worker` job.
An example run:
```ruby
post1 = Post.create(title: 'Critique of Pure Reason', author: 'Immanuel Kant') #=> <Post id: 1, title: 'Critique of Pure Reason'...>
post2 = Post.create(title: 'The Social Contract', author: 'Jean-Jacques Rousseau') #=> <Post id: 2, title: 'The Social Contract'...>
post1.serially.start!
post2.serially.start!
```
The resulting resque log may look something like this:
```
Post 1 drafted
Post 1 reviewed by staff
Post 2 drafted
Post 1 not published - bibliography is missing
Post 2 reviewed by staff
Post 2 not published - bibliography is missing
```

### Task Return Values

* A task should at minimum return a boolean value, signifying whether that task finished successfully or not
* A task can also return a string with details of the task completion
* If a task returns _false_, the execution stops and the next tasks in the chain won't be performed for current instance

### Inspecting Task Runs

You can inspect task runs results using the provided `Serially::TaskRun` model and its associated `serially_task_runs` table.
Running `Serially::TaskRun.all` for the above example, will show something like this:
```
+----+------------+---------+-----------+----------------+----------------------+---------------------+
| id | item_class | item_id | task_name | status         | result_message       | finished_at         |
+----+------------+---------+-----------+----------------+----------------------+---------------------+
| 1  | Post       | 1       | draft     | finished_ok    |                      | 2015-12-31 09:17:17 |
| 2  | Post       | 1       | review    | finished_ok    | reviewed by staff    | 2015-12-31 09:17:17 |
| 3  | Post       | 2       | draft     | finished_ok    |                      | 2015-12-31 09:17:17 |
| 4  | Post       | 1       | publish   | finished_error | bibliography missing | 2015-12-31 09:17:17 |
| 5  | Post       | 2       | review    | finished_ok    |                      | 2015-12-31 09:17:17 |
| 6  | Post       | 2       | publish   | finished_error | bibliography missing | 2015-12-31 09:17:17 |
+----+------------+---------+-----------+----------------+----------------------+---------------------+
```
Notice that the _promote_ task didn't run at all, since the _publish_ task that ran before it returned _false_ for both posts.


### Blocks
In addition to instance methods, you can pass a block as a task callback, and you can mix both syntaxes in your class:

```ruby
class Post < ActiveRecord::Base
     include Serially

     serially do
        task :draft
        task :review do |post|
            puts "Reviewing #{post.id}"
        end
        task :publish do |post|
            puts "Publishing #{post.id}"
        end
     end

     def draft
        puts "Drafting #{self.id}"
     end
end
```

## Customizing Instance Creation
Before the first task runs, an instance of your class is created, on which your task callbacks are then called. By default, instances of plain ruby classes
are created using `new(self.instance_args)`, while instances of ActiveRecord models are loaded using `where(self.instance_args).first`.

### Plain Ruby Class
The default implementation of `instance_args` for a plain ruby class returns nil (in which case `new` is called without arguments). You can provide your own
implementation of `instance_args`, and then it will be used when instantiating an instance:

```ruby
class MyClass
     include Serially

     attr_accessor :some_key
     def initialize(args)
        @some_key = args[:some_key]
     end

     def instance_args
        {some_key: self.some_key}
     end


     serially do
        task :do_this
        task :do_that
     end

     def do_this
        puts "Doing this for instance with some_key=#{self.some_key}"
     end
     def do_that
        puts "Doing that for instance with some_key=#{self.some_key}"
     end
end

# somewhere in your code you create an instance of your class and call #serially.start!
my = MyClass.new(some_key: "IamMe")
my.serially.start!   # Serially::Worker is enqueued in resque queue

# resque picks up the job, creates an instance of your class using self.instance_args 
# your provided, and starts executing your tasks
```

Here's the resulting resque log:
```
Doing this for instance with some_key=IamMe
Doing that for instance with some_key=IamMe
```

### ActiveRecord Model


## Termination


## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mikemarsian/serially.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

[1]: https://github.com/mikemarsian/serially-demo