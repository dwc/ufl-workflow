# Introduction #

UFL-Workflow is a Web application which you can use to track requests through processes that you define.

For example, professors at the [University of Florida](http://www.ufl.edu/) must submit forms to create new undergraduate and graduate courses. These forms were historically sent via snail mail to each office that approved them. UFL-Workflow makes this process electronic, where the documentation is readily available and easily searchable.

Before getting started, you will need access to an IBM DB2 database (version 8 or higher).

# Downloading #

You can download the latest release from the project home page, or you can checkout the source via the "Source" tab.

Before running the application, you will most likely need to install some additional modules on your system. It is based on the [Catalyst framework](http://www.catalystframework.org/). Once you've downloaded the source, check what you're missing by running the following command in a terminal:

```
perl Makefile.PL
```

Install any missing dependencies via [CPAN](http://search.cpan.org/dist/CPAN/) or your preferred package manager. If you decide to use CPAN, you might consider using [local::lib](http://search.cpan.org/dist/local-lib/) to isolate the libraries for UFL-Workflow.

# Configuring #

We provide a default configuration with the application, located at `ufl_workflow.yml`. We also provide a sample "local" configuration, located at `ufl_workflow_local_sample.yml`, which you can use to override the defaults.

At the very least, you should update the database connection information under `Model::DBIC`.

These configuration files use YAML, but you can use another format. See [Catalyst::Plugin::ConfigLoader](http://search.cpan.org/dist/Catalyst-Plugin-ConfigLoader/) for more information.

# Creating the database #

We also provide a script to create an initial database. This script requires an established DB2 connection (via the `db2` command line tool). From there, run:

```
./script/ufl_workflow_generate_schema.pl | db2 -vtd%
```

This script creates an empty database. To add some data to get started, run:

```
db2 -tvf db/default_data.sql
```

# Running #

Now you should be able to run the built-in development server. This server allows you to run the application for testing purposes. From your UFL-Workflow directory in a terminal, run:

```
./script/ufl_workflow_server.pl -r
```

Once loaded, the script will tell you to connect to e.g. http://localhost:3000/.

The default data contains a test process, to which you can add requests to test the system.

See TrackingRequests for an example of how the system operates.