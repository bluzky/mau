# Web Templates Examples

Real-world examples of HTML and web templating with Mau.

## Overview

This guide provides copy-paste ready web template examples for common HTML patterns, including navigation menus, dynamic content, and SEO meta tags.

## Basic HTML Page

Simple HTML page with dynamic content.

```elixir
template = """
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>{{ page_title }}</title>
  <meta name="description" content="{{ page_description }}">
</head>
<body>
  <h1>{{ page_title }}</h1>
  <p>{{ content }}</p>
  <footer>
    <p>&copy; {{ year }} My Company. All rights reserved.</p>
  </footer>
</body>
</html>
"""

context = %{
  "page_title" => "Welcome to My Site",
  "page_description" => "An amazing website built with Mau",
  "content" => "This is the main content of the page.",
  "year" => 2024
}

{:ok, html} = Mau.render(template, context)
```

**Output:**
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Welcome to My Site</title>
  <meta name="description" content="An amazing website built with Mau">
</head>
<body>
  <h1>Welcome to My Site</h1>
  <p>This is the main content of the page.</p>
  <footer>
    <p>&copy; 2024 My Company. All rights reserved.</p>
  </footer>
</body>
</html>
```

---

## Navigation Menu

Dynamic navigation with active state highlighting.

```elixir
template = """
<nav class="navbar">
  <ul class="nav-list">
    {% for item in nav_items %}
    <li class="nav-item">
      <a href="{{ item.url }}"
         class="nav-link {% if item.url == current_path %}active{% endif %}">
        {{ item.label }}
      </a>
    </li>
    {% endfor %}
  </ul>
</nav>
"""

context = %{
  "nav_items" => [
    %{"label" => "Home", "url" => "/"},
    %{"label" => "About", "url" => "/about"},
    %{"label" => "Services", "url" => "/services"},
    %{"label" => "Contact", "url" => "/contact"}
  ],
  "current_path" => "/about"
}

{:ok, html} = Mau.render(template, context)
```

**Output:**
```html
<nav class="navbar">
  <ul class="nav-list">
    <li class="nav-item">
      <a href="/" class="nav-link">Home</a>
    </li>
    <li class="nav-item">
      <a href="/about" class="nav-link active">About</a>
    </li>
    <li class="nav-item">
      <a href="/services" class="nav-link">Services</a>
    </li>
    <li class="nav-item">
      <a href="/contact" class="nav-link">Contact</a>
    </li>
  </ul>
</nav>
```

---

## Product Listing

Display products with conditional pricing and availability.

```elixir
template = """
<div class="products">
  {% for product in products %}
  <div class="product-card">
    <h3>{{ product.name }}</h3>
    <p>{{ product.description | truncate: 100 }}</p>

    <div class="product-info">
      {% if product.on_sale %}
      <p class="price">
        <span class="original">${{ product.original_price }}</span>
        <span class="sale">${{ product.price }}</span>
        <span class="discount">{{ product.discount }}% OFF</span>
      </p>
      {% else %}
      <p class="price">${{ product.price | round: 2 }}</p>
      {% endif %}

      <p class="availability">
        {% if product.in_stock %}
        <span class="in-stock">In Stock ({{ product.quantity }} available)</span>
        {% else %}
        <span class="out-of-stock">Out of Stock</span>
        {% endif %}
      </p>

      <button class="btn" {% unless product.in_stock %}disabled{% endunless %}>
        Add to Cart
      </button>
    </div>
  </div>
  {% endfor %}
</div>
"""

context = %{
  "products" => [
    %{
      "name" => "Laptop",
      "description" => "High-performance laptop perfect for developers and content creators",
      "price" => 999.99,
      "original_price" => 1299.99,
      "on_sale" => true,
      "discount" => 23,
      "in_stock" => true,
      "quantity" => 5
    },
    %{
      "name" => "Mouse",
      "description" => "Ergonomic wireless mouse with 5 programmable buttons",
      "price" => 29.99,
      "original_price" => 29.99,
      "on_sale" => false,
      "discount" => 0,
      "in_stock" => true,
      "quantity" => 15
    },
    %{
      "name" => "Monitor",
      "description" => "4K Ultra HD monitor with USB-C connectivity",
      "price" => 499.99,
      "original_price" => 499.99,
      "on_sale" => false,
      "discount" => 0,
      "in_stock" => false,
      "quantity" => 0
    }
  ]
}

{:ok, html} = Mau.render(template, context)
```

**Output:**
```html
<div class="products">
  <div class="product-card">
    <h3>Laptop</h3>
    <p>High-performance laptop perfect for developers and content creators</p>

    <div class="product-info">
      <p class="price">
        <span class="original">$1299.99</span>
        <span class="sale">$999.99</span>
        <span class="discount">23% OFF</span>
      </p>

      <p class="availability">
        <span class="in-stock">In Stock (5 available)</span>
      </p>

      <button class="btn">Add to Cart</button>
    </div>
  </div>
  <!-- More products... -->
</div>
```

---

## User Profile Card

Display user information with avatar and stats.

```elixir
template = """
<div class="profile-card">
  <div class="header" style="background-color: {{ user.header_color }}">
    <img src="{{ user.avatar }}" alt="{{ user.name }}" class="avatar">
  </div>

  <div class="content">
    <h2>{{ user.name }}</h2>
    {% if user.title %}<p class="title">{{ user.title }}</p>{% endif %}
    {% if user.bio %}<p class="bio">{{ user.bio }}</p>{% endif %}

    <div class="stats">
      <div class="stat">
        <span class="number">{{ user.followers | length }}</span>
        <span class="label">Followers</span>
      </div>
      <div class="stat">
        <span class="number">{{ user.posts | length }}</span>
        <span class="label">Posts</span>
      </div>
      <div class="stat">
        <span class="number">{{ user.likes | length }}</span>
        <span class="label">Likes</span>
      </div>
    </div>

    {% if user.verified %}
    <div class="verified-badge">✓ Verified</div>
    {% endif %}

    <button class="follow-btn">Follow</button>
  </div>
</div>
"""

context = %{
  "user" => %{
    "name" => "Alice Johnson",
    "avatar" => "https://example.com/alice.jpg",
    "title" => "Product Designer",
    "bio" => "Creating beautiful and functional designs | Coffee enthusiast",
    "header_color" => "#3498db",
    "verified" => true,
    "followers" => [1, 2, 3, 4, 5],  # Simplified for example
    "posts" => [1, 2, 3, 4, 5, 6, 7, 8],
    "likes" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
  }
}

{:ok, html} = Mau.render(template, context)
```

**Output:**
```html
<div class="profile-card">
  <div class="header" style="background-color: #3498db">
    <img src="https://example.com/alice.jpg" alt="Alice Johnson" class="avatar">
  </div>

  <div class="content">
    <h2>Alice Johnson</h2>
    <p class="title">Product Designer</p>
    <p class="bio">Creating beautiful and functional designs | Coffee enthusiast</p>

    <div class="stats">
      <div class="stat">
        <span class="number">5</span>
        <span class="label">Followers</span>
      </div>
      <div class="stat">
        <span class="number">8</span>
        <span class="label">Posts</span>
      </div>
      <div class="stat">
        <span class="number">12</span>
        <span class="label">Likes</span>
      </div>
    </div>

    <div class="verified-badge">✓ Verified</div>

    <button class="follow-btn">Follow</button>
  </div>
</div>
```

---

## Blog Post with Comments

Display a blog post with comments section.

```elixir
template = """
<article class="blog-post">
  <header class="post-header">
    <h1>{{ post.title }}</h1>
    <div class="meta">
      <span class="author">By {{ post.author }}</span>
      <span class="date">{{ post.published_date }}</span>
      <span class="reading-time">{{ post.content | split: " " | length | divided_by: 200 | round }} min read</span>
    </div>
  </header>

  <div class="post-content">
    {{ post.content }}
  </div>

  <footer class="post-footer">
    <div class="tags">
      {% for tag in post.tags %}
      <a href="/blog/tag/{{ tag | lower_case | replace: ' ', '-' }}" class="tag">{{ tag }}</a>
      {% endfor %}
    </div>
  </footer>
</article>

<section class="comments">
  <h3>Comments ({{ post.comments | length }})</h3>

  {% if post.comments | length > 0 %}
    {% for comment in post.comments %}
    <div class="comment">
      <div class="comment-header">
        <strong>{{ comment.author }}</strong>
        <span class="timestamp">{{ comment.date }}</span>
      </div>
      <p class="comment-text">{{ comment.text }}</p>
      {% if comment.replies | length > 0 %}
      <div class="replies">
        {% for reply in comment.replies %}
        <div class="reply">
          <strong>{{ reply.author }}</strong>: {{ reply.text }}
        </div>
        {% endfor %}
      </div>
      {% endif %}
    </div>
    {% endfor %}
  {% else %}
    <p>No comments yet. Be the first to comment!</p>
  {% endif %}
</section>
"""

context = %{
  "post" => %{
    "title" => "Getting Started with Mau",
    "author" => "Jane Developer",
    "published_date" => "October 29, 2024",
    "content" => "Mau is a powerful template engine...", # Simplified for example
    "tags" => ["Templating", "Elixir", "Web Development"],
    "comments" => [
      %{
        "author" => "John Reader",
        "date" => "Oct 29",
        "text" => "Great article! Very helpful.",
        "replies" => [
          %{
            "author" => "Jane Developer",
            "text" => "Thank you! Glad you found it helpful."
          }
        ]
      },
      %{
        "author" => "Sarah Code",
        "date" => "Oct 28",
        "text" => "Can you write about advanced features next?",
        "replies" => []
      }
    ]
  }
}

{:ok, html} = Mau.render(template, context)
```

---

## Table with Sorting Indicators

Display a data table with sort indicators.

```elixir
template = """
<table class="data-table">
  <thead>
    <tr>
      <th>
        <a href="?sort=name" class="sort-link">
          Name
          {% if sort_field == 'name' %}
            <span class="sort-indicator">{{ sort_order == 'asc' ? '↑' : '↓' }}</span>
          {% endif %}
        </a>
      </th>
      <th>
        <a href="?sort=email" class="sort-link">
          Email
          {% if sort_field == 'email' %}
            <span class="sort-indicator">{{ sort_order == 'asc' ? '↑' : '↓' }}</span>
          {% endif %}
        </a>
      </th>
      <th>Status</th>
      <th>Joined</th>
    </tr>
  </thead>
  <tbody>
    {% for user in users %}
    <tr class="{% if user.status == 'active' %}row-active{% else %}row-inactive{% endif %}">
      <td>{{ user.name }}</td>
      <td>{{ user.email }}</td>
      <td>
        <span class="badge badge-{{ user.status }}">{{ user.status | capitalize }}</span>
      </td>
      <td>{{ user.joined_date }}</td>
    </tr>
    {% endfor %}
  </tbody>
</table>
"""

context = %{
  "sort_field" => "name",
  "sort_order" => "asc",
  "users" => [
    %{"name" => "Alice", "email" => "alice@example.com", "status" => "active", "joined_date" => "2024-01-15"},
    %{"name" => "Bob", "email" => "bob@example.com", "status" => "inactive", "joined_date" => "2024-02-20"},
    %{"name" => "Charlie", "email" => "charlie@example.com", "status" => "active", "joined_date" => "2024-03-10"}
  ]
}

{:ok, html} = Mau.render(template, context)
```

---

## Form with Validation Messages

Display a form with conditional validation errors.

```elixir
template = """
<form class="contact-form" method="post">
  <div class="form-group">
    <label for="name">Name</label>
    <input
      type="text"
      id="name"
      name="name"
      value="{{ form.name }}"
      class="form-control {% if form.errors.name %}is-invalid{% endif %}"
    >
    {% if form.errors.name %}
    <div class="error-message">{{ form.errors.name }}</div>
    {% endif %}
  </div>

  <div class="form-group">
    <label for="email">Email</label>
    <input
      type="email"
      id="email"
      name="email"
      value="{{ form.email }}"
      class="form-control {% if form.errors.email %}is-invalid{% endif %}"
    >
    {% if form.errors.email %}
    <div class="error-message">{{ form.errors.email }}</div>
    {% endif %}
  </div>

  <div class="form-group">
    <label for="message">Message</label>
    <textarea
      id="message"
      name="message"
      class="form-control {% if form.errors.message %}is-invalid{% endif %}"
      rows="5">{{ form.message }}</textarea>
    {% if form.errors.message %}
    <div class="error-message">{{ form.errors.message }}</div>
    {% endif %}
  </div>

  <button type="submit" class="btn btn-primary">Send Message</button>
</form>
"""

context = %{
  "form" => %{
    "name" => "John",
    "email" => "",
    "message" => "I have a question...",
    "errors" => %{
      "name" => nil,
      "email" => "Email is required",
      "message" => nil
    }
  }
}

{:ok, html} = Mau.render(template, context)
```

---

## Pagination Controls

Display pagination with active page highlighting.

```elixir
template = """
<div class="pagination">
  {% if current_page > 1 %}
  <a href="?page=1" class="page-link">« First</a>
  <a href="?page={{ current_page | minus: 1 }}" class="page-link">‹ Previous</a>
  {% endif %}

  {% for page in pages %}
    {% if page == current_page %}
    <span class="page-link active">{{ page }}</span>
    {% else %}
    <a href="?page={{ page }}" class="page-link">{{ page }}</a>
    {% endif %}
  {% endfor %}

  {% if current_page < total_pages %}
  <a href="?page={{ current_page | plus: 1 }}" class="page-link">Next ›</a>
  <a href="?page={{ total_pages }}" class="page-link">Last »</a>
  {% endif %}
</div>
"""

context = %{
  "current_page" => 3,
  "total_pages" => 10,
  "pages" => [1, 2, 3, 4, 5]
}

{:ok, html} = Mau.render(template, context)
```

---

## Breadcrumb Navigation

Display breadcrumb navigation trail.

```elixir
template = """
<nav aria-label="breadcrumb">
  <ol class="breadcrumb">
    {% for item in breadcrumbs %}
    <li class="breadcrumb-item {% if forloop.last %}active{% endif %}">
      {% if forloop.last %}
        {{ item.label }}
      {% else %}
        <a href="{{ item.url }}">{{ item.label }}</a>
      {% endif %}
    </li>
    {% endfor %}
  </ol>
</nav>
"""

context = %{
  "breadcrumbs" => [
    %{"label" => "Home", "url" => "/"},
    %{"label" => "Products", "url" => "/products"},
    %{"label" => "Electronics", "url" => "/products/electronics"},
    %{"label" => "Laptops", "url" => nil}  # Current page
  ]
}

{:ok, html} = Mau.render(template, context)
```

---

## Alert/Notification Component

Display alerts with different severity levels.

```elixir
template = """
{% for notification in notifications %}
<div class="alert alert-{{ notification.type }}">
  <span class="alert-icon">
    {% case notification.type %}
    {% when "success" %}✓
    {% when "error" %}✕
    {% when "warning" %}⚠
    {% when "info" %}ⓘ
    {% endcase %}
  </span>
  <span class="alert-message">{{ notification.message }}</span>
  {% if notification.dismissible %}
  <button class="alert-close" aria-label="Close">×</button>
  {% endif %}
</div>
{% endfor %}
"""

context = %{
  "notifications" => [
    %{"type" => "success", "message" => "Your changes have been saved.", "dismissible" => false},
    %{"type" => "error", "message" => "An error occurred while processing your request.", "dismissible" => true},
    %{"type" => "warning", "message" => "This action cannot be undone.", "dismissible" => true},
    %{"type" => "info", "message" => "New version available. Click to update.", "dismissible" => false}
  ]
}

{:ok, html} = Mau.render(template, context)
```

---

## See Also

- [Email Templates](email-templates.md) - Email template examples
- [Report Generation](report-generation.md) - Data report examples
- [Data Transformation](data-transformation.md) - Using map directives
- [Template Syntax Guide](../guides/template-syntax.md) - Template language reference
- [Filters Guide](../guides/filters.md) - Using filters in templates
