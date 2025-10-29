# Your First Template

Build a complete, realistic template from scratch.

## Project: User Profile Page

We'll create a user profile page template that displays user information with conditional sections.

## Step 1: Define Your Context

First, gather the data you want to display:

```elixir
context = %{
  "user" => %{
    "name" => "Alice Johnson",
    "email" => "alice@example.com",
    "role" => "admin",
    "active" => true,
    "joined_date" => "2023-01-15",
    "profile" => %{
      "bio" => "Passionate about Elixir and functional programming",
      "location" => "San Francisco, CA",
      "website" => "https://alice.dev"
    }
  },
  "company" => %{
    "name" => "Tech Startup Inc",
    "industry" => "Software Development"
  },
  "projects" => [
    %{"name" => "Phoenix API", "status" => "active"},
    %{"name" => "Elixir Utilities", "status" => "active"},
    %{"name" => "Old Project", "status" => "archived"}
  ]
}
```

## Step 2: Write the Template

Create a template that renders the profile:

```elixir
template = """
# {{ user.name }}

**Role:** {{ user.role | capitalize }}
**Email:** {{ user.email }}
**Status:** {% if user.active %}Active{% else %}Inactive{% endif %}
**Member Since:** {{ user.joined_date }}

## Bio
{{ user.profile.bio }}

## Contact Information
- **Location:** {{ user.profile.location }}
- **Website:** {{ user.profile.website }}
- **Company:** {{ company.name }} ({{ company.industry }})

## Projects ({{ projects | length }})
{% for project in projects %}
- **{{ project.name }}** - {{ project.status | capitalize }}
{% endfor %}

{% if user.role == "admin" %}

## Admin Section
You have administrative privileges in this system.

### Quick Actions
- Manage Users
- System Settings
- View Logs

{% endif %}
"""
```

## Step 3: Render the Template

```elixir
{:ok, result} = Mau.render(template, context)
IO.puts(result)
```

## Expected Output

```
# Alice Johnson

**Role:** Admin
**Email:** alice@example.com
**Status:** Active
**Member Since:** 2023-01-15

## Bio
Passionate about Elixir and functional programming

## Contact Information
- **Location:** San Francisco, CA
- **Website:** https://alice.dev
- **Company:** Tech Startup Inc (Software Development)

## Projects (3)
- **Phoenix API** - Active
- **Elixir Utilities** - Active
- **Old Project** - Archived

## Admin Section
You have administrative privileges in this system.

### Quick Actions
- Manage Users
- System Settings
- View Logs
```

## Walkthrough: What's Happening

### 1. Simple Interpolation
```
{{ user.name }}  →  "Alice Johnson"
```
Access nested properties with dot notation.

### 2. Filters
```
{{ user.role | capitalize }}  →  "Admin"
```
Transforms the value before display.

### 3. Conditionals
```
{% if user.active %}Active{% else %}Inactive{% endif %}
```
Renders different text based on conditions.

### 4. List Length
```
{{ projects | length }}  →  "3"
```
Count items in a collection.

### 5. Loops
```
{% for project in projects %}
  - **{{ project.name }}** - {{ project.status | capitalize }}
{% endfor %}
```
Iterates through each item in the list.

### 6. Role-Based Sections
```
{% if user.role == "admin" %}
  {# Admin content #}
{% endif %}
```
Show different content based on user role.

## Variations and Exercises

### Exercise 1: Add Member Status Badge

Modify the status line to show different badges:

```elixir
**Status:**
{% if user.active %}
  🟢 Active
{% else %}
  🔴 Inactive
{% endif %}
```

### Exercise 2: Filter Active Projects

Show only active projects:

```elixir
## Active Projects
{% for project in projects %}
  {% if project.status == "active" %}
    - {{ project.name }}
  {% endif %}
{% endfor %}
```

### Exercise 3: Add Last Login

Add to context:
```elixir
context = %{
  # ... existing data
  "last_login" => "2024-01-29T14:30:00Z"
}
```

Then in template:
```elixir
**Last Login:** {{ last_login }}
```

### Exercise 4: Role-Based Menu

```elixir
{% if user.role == "admin" %}
  [Admin Dashboard]
{% elsif user.role == "moderator" %}
  [Moderation Panel]
{% else %}
  [User Settings]
{% endif %}
```

## Common Patterns

### 1. Conditional Rendering

```elixir
{% if user.profile.bio %}
  <div class="bio">{{ user.profile.bio }}</div>
{% endif %}
```

This checks if bio exists before showing it.

### 2. List with Fallback

```elixir
{% if projects %}
  {% for project in projects %}
    - {{ project.name }}
  {% endfor %}
{% else %}
  No projects yet
{% endif %}
```

### 3. Formatted Lists

```elixir
{% for project in projects %}
  {% if forloop.first %}(1){% else %}, ({{ forloop.index }}){% endif %} {{ project.name }}
{% endfor %}
```

Output: `(1) Phoenix API, (2) Elixir Utilities, (3) Old Project`

### 4. Empty vs Populated

```elixir
{% if user.projects %}
  Projects: {{ user.projects | join(", ") }}
{% else %}
  No projects
{% endif %}
```

## Debugging Tips

### Check Your Context

Print context to verify data structure:

```elixir
IO.inspect(context, pretty: true)
```

### Test Small Pieces

Before building the full template, test individual expressions:

```elixir
Mau.render("{{ user.name }}", context)
Mau.render("{{ user.role | capitalize }}", context)
```

### Handle Missing Data

Always check if data exists before accessing it:

```elixir
{% if user.profile %}
  Bio: {{ user.profile.bio }}
{% endif %}
```

### Preview Output

Render to a temporary file and check formatting:

```elixir
{:ok, result} = Mau.render(template, context)
File.write!("preview.txt", result)
```

## Next Steps

Now that you understand the basics, explore more advanced features:

- [Filters Guide](../guides/filters.md) - More powerful filters
- [Control Flow Guide](../guides/control-flow.md) - Advanced conditionals
- [Map Directives Guide](../guides/map-rendering.md) - Transform nested data
- [Report Generation Example](../examples/report-generation.md) - Real-world use cases

## Key Takeaways

✅ Templates combine text, variables, and logic
✅ Use `{{ }}` for dynamic content
✅ Use `{% %}` for logic (if, for)
✅ Chain filters with `|` to transform data
✅ Conditionals show/hide content
✅ Loops iterate over collections
✅ Always handle missing or empty data

You're ready to build templates! Start with simple examples and gradually add complexity.
