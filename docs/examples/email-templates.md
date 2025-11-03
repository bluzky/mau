# Email Templates Examples

Real-world email template examples for common use cases.

## Overview

This guide provides copy-paste ready email templates for common business scenarios like welcome emails, order confirmations, password resets, and newsletters.

## Welcome Email

Send a personalized welcome email to new users.

```elixir
template = """
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #3498db; color: white; padding: 20px; text-align: center; }
    .button { background-color: #3498db; color: white; padding: 10px 20px; text-decoration: none; display: inline-block; margin-top: 20px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Welcome to {{ company_name }}!</h1>
    </div>

    <h2>Hi {{ user.first_name }},</h2>

    <p>We're thrilled to have you join our community! Your account has been successfully created.</p>

    <h3>What's Next?</h3>
    <ul>
      <li>Complete your profile with additional information</li>
      <li>Explore our features and tools</li>
      <li>Join our community forum</li>
      <li>Check out our getting started guide</li>
    </ul>

    <p>
      <a href="{{ action_url }}" class="button">Get Started</a>
    </p>

    <h3>Questions?</h3>
    <p>If you have any questions or need help, don't hesitate to reach out to our support team at <a href="mailto:{{ support_email }}">{{ support_email }}</a></p>

    <p>Best regards,<br>
    The {{ company_name }} Team</p>

    <hr style="margin-top: 40px; border: none; border-top: 1px solid #ddd;">
    <p style="font-size: 12px; color: #666;">
      {{ company_address }}<br>
      <a href="{{ unsubscribe_url }}">Unsubscribe</a>
    </p>
  </div>
</body>
</html>
"""

context = %{
  "company_name" => "TechFlow",
  "company_address" => "123 Main St, San Francisco, CA 94102",
  "user" => %{"first_name" => "Alice"},
  "action_url" => "https://example.com/onboarding",
  "support_email" => "support@example.com",
  "unsubscribe_url" => "https://example.com/unsubscribe?token=xyz"
}

{:ok, email_html} = Mau.render(template, context)
```

---

## Order Confirmation Email

Confirm an order with details and next steps.

```elixir
template = """
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    table { width: 100%; border-collapse: collapse; margin: 20px 0; }
    th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background-color: #f5f5f5; font-weight: bold; }
    .total { font-size: 18px; font-weight: bold; text-align: right; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Order Confirmation</h1>

    <p>Hi {{ customer.name }},</p>

    <p>Thank you for your order! We're processing it now.</p>

    <h3>Order Details</h3>
    <p><strong>Order #:</strong> {{ order.id }}</p>
    <p><strong>Order Date:</strong> {{ order.date }}</p>
    <p><strong>Estimated Delivery:</strong> {{ order.estimated_delivery }}</p>

    <h3>Items</h3>
    <table>
      <thead>
        <tr>
          <th>Product</th>
          <th>Quantity</th>
          <th>Price</th>
          <th>Total</th>
        </tr>
      </thead>
      <tbody>
        {% for item in order.items %}
        <tr>
          <td>{{ item.name }}</td>
          <td>{{ item.quantity }}</td>
          <td>${{ item.price | round: 2 }}</td>
          <td>${{ item.total | round: 2 }}</td>
        </tr>
        {% endfor %}
      </tbody>
    </table>

    <div style="text-align: right; padding: 10px 0; border-top: 2px solid #333;">
      <p style="margin: 10px 0;"><strong>Subtotal:</strong> ${{ order.subtotal | round: 2 }}</p>
      <p style="margin: 10px 0;"><strong>Tax:</strong> ${{ order.tax | round: 2 }}</p>
      <p style="margin: 10px 0; font-size: 18px;"><strong>Total:</strong> ${{ order.total | round: 2 }}</p>
    </div>

    <h3>Shipping Address</h3>
    <p>
      {{ order.shipping.name }}<br>
      {{ order.shipping.street }}<br>
      {{ order.shipping.city }}, {{ order.shipping.state }} {{ order.shipping.zip }}<br>
      {{ order.shipping.country }}
    </p>

    <h3>Track Your Order</h3>
    <p>You can track your order here: <a href="{{ tracking_url }}">{{ tracking_url }}</a></p>

    <p>Thank you for your business!</p>
  </div>
</body>
</html>
"""

context = %{
  "customer" => %{"name" => "Bob Johnson"},
  "order" => %{
    "id" => "ORD-2024-001234",
    "date" => "2024-10-29",
    "estimated_delivery" => "2024-11-05",
    "items" => [
      %{"name" => "Laptop", "quantity" => 1, "price" => 999.99, "total" => 999.99},
      %{"name" => "Mouse", "quantity" => 2, "price" => 29.99, "total" => 59.98}
    ],
    "subtotal" => 1059.97,
    "tax" => 84.80,
    "total" => 1144.77,
    "shipping" => %{
      "name" => "Bob Johnson",
      "street" => "456 Oak Ave",
      "city" => "Portland",
      "state" => "OR",
      "zip" => "97205",
      "country" => "USA"
    }
  },
  "tracking_url" => "https://example.com/track/ORD-2024-001234"
}

{:ok, email_html} = Mau.render(template, context)
```

---

## Password Reset Email

Guide users to reset their password securely.

```elixir
template = """
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .warning { background-color: #fff3cd; border: 1px solid #ffc107; padding: 15px; border-radius: 4px; margin: 20px 0; }
    .code-block { background-color: #f5f5f5; padding: 15px; border-radius: 4px; font-family: monospace; margin: 15px 0; }
    .button { background-color: #28a745; color: white; padding: 12px 30px; text-decoration: none; display: inline-block; border-radius: 4px; margin-top: 20px; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Password Reset Request</h1>

    <p>Hi {{ user.name }},</p>

    <p>We received a request to reset the password for your account associated with <strong>{{ user.email }}</strong>.</p>

    <div class="warning">
      <strong>⚠️ Security Note:</strong> If you didn't request this password reset, you can safely ignore this email. Your password will remain unchanged.
    </div>

    <h3>Reset Your Password</h3>
    <p>Click the button below to reset your password. This link will expire in {{ expiration_hours }} hours.</p>

    <p>
      <a href="{{ reset_url }}" class="button">Reset Password</a>
    </p>

    <h3>Or use this code:</h3>
    <div class="code-block">
      {{ reset_code }}
    </div>

    <p>If you can't click the button, copy and paste this URL into your browser:</p>
    <p style="word-break: break-all; font-size: 12px; color: #666;">
      {{ reset_url }}
    </p>

    <h3>Questions?</h3>
    <p>If you didn't request a password reset or have any questions, please contact our support team at <a href="mailto:{{ support_email }}">{{ support_email }}</a></p>

    <p>Stay safe!<br>
    The {{ company_name }} Team</p>
  </div>
</body>
</html>
"""

context = %{
  "company_name" => "TechFlow",
  "user" => %{
    "name" => "Charlie",
    "email" => "charlie@example.com"
  },
  "reset_url" => "https://example.com/reset-password?token=abc123def456",
  "reset_code" => "ABC123DEF456",
  "expiration_hours" => 24,
  "support_email" => "support@example.com"
}

{:ok, email_html} = Mau.render(template, context)
```

---

## Newsletter Email

Send a newsletter with multiple sections and featured content.

```elixir
template = """
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; background-color: #f5f5f5; }
    .container { max-width: 600px; margin: 0 auto; background-color: white; padding: 20px; }
    .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px 20px; text-align: center; }
    .section { margin: 30px 0; padding: 20px; border: 1px solid #eee; border-radius: 4px; }
    .feature-image { max-width: 100%; height: auto; }
    .cta { background-color: #667eea; color: white; padding: 10px 20px; text-decoration: none; display: inline-block; border-radius: 4px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>{{ newsletter.title }}</h1>
      <p>{{ newsletter.month }}</p>
    </div>

    <p>Hi {{ subscriber.name }},</p>

    <p>{{ newsletter.intro }}</p>

    {% for article in newsletter.featured_articles %}
    <div class="section">
      <h2>{{ article.title }}</h2>
      {% if article.image_url %}
      <img src="{{ article.image_url }}" alt="{{ article.title }}" class="feature-image" style="margin: 15px 0;">
      {% endif %}
      <p>{{ article.summary }}</p>
      <p>
        <a href="{{ article.url }}" class="cta">Read More →</a>
      </p>
    </div>
    {% endfor %}

    <div class="section">
      <h3>✨ This Month's Highlights</h3>
      <ul>
        {% for highlight in newsletter.highlights %}
        <li>{{ highlight }}</li>
        {% endfor %}
      </ul>
    </div>

    {% if newsletter.upcoming_events | length > 0 %}
    <div class="section">
      <h3>📅 Upcoming Events</h3>
      {% for event in newsletter.upcoming_events %}
      <p>
        <strong>{{ event.name }}</strong><br>
        {{ event.date }} at {{ event.time }}<br>
        <a href="{{ event.url }}">Register →</a>
      </p>
      {% endfor %}
    </div>
    {% endif %}

    <div class="section" style="background-color: #f9f9f9;">
      <h3>Got Feedback?</h3>
      <p>We'd love to hear from you! Reply to this email with your thoughts, suggestions, or questions.</p>
    </div>

    <hr style="margin: 20px 0; border: none; border-top: 1px solid #ddd;">
    <p style="font-size: 12px; color: #666;">
      You're receiving this email because you're subscribed to {{ newsletter.name }}.<br>
      <a href="{{ unsubscribe_url }}">Unsubscribe</a> | <a href="{{ preferences_url }}">Update Preferences</a><br>
      © {{ year }} {{ company_name }}. All rights reserved.
    </p>
  </div>
</body>
</html>
"""

context = %{
  "company_name" => "TechFlow",
  "newsletter" => %{
    "name" => "TechFlow Digest",
    "title" => "TechFlow Digest - October 2024",
    "month" => "October 2024",
    "intro" => "Your monthly roundup of the latest updates, articles, and insights from the TechFlow community.",
    "featured_articles" => [
      %{
        "title" => "Getting Started with Advanced Templating",
        "summary" => "Learn how to leverage template directives for complex data transformations.",
        "image_url" => "https://example.com/articles/templating.jpg",
        "url" => "https://blog.example.com/templating"
      },
      %{
        "title" => "Performance Tips for Large-Scale Systems",
        "summary" => "Best practices for optimizing your applications for production workloads.",
        "image_url" => "https://example.com/articles/performance.jpg",
        "url" => "https://blog.example.com/performance"
      }
    ],
    "highlights" => [
      "Version 2.0 is now available with 50+ new features",
      "Join our community webinar on November 5th",
      "Special 30% discount for annual plans until end of month"
    ],
    "upcoming_events" => [
      %{
        "name" => "Advanced Workshop",
        "date" => "November 5, 2024",
        "time" => "2:00 PM EST",
        "url" => "https://example.com/events/workshop"
      },
      %{
        "name" => "Community Meetup",
        "date" => "November 12, 2024",
        "time" => "6:00 PM EST",
        "url" => "https://example.com/events/meetup"
      }
    ]
  },
  "subscriber" => %{"name" => "Diana"},
  "year" => 2024,
  "unsubscribe_url" => "https://example.com/unsubscribe?token=xyz",
  "preferences_url" => "https://example.com/preferences?token=xyz"
}

{:ok, email_html} = Mau.render(template, context)
```

---

## Invitation Email

Invite users to join a team or event.

```elixir
template = """
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .invite-card { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 8px; text-align: center; margin: 20px 0; }
    .button { background-color: white; color: #667eea; padding: 12px 30px; text-decoration: none; display: inline-block; border-radius: 4px; font-weight: bold; margin-top: 15px; }
  </style>
</head>
<body>
  <div class="container">
    <h1>You're Invited!</h1>

    <p>Hi {{ invited_user.name }},</p>

    <p>{{ inviter.name }} has invited you to join <strong>{{ team_name }}</strong>{% if team_type %} as a {{ team_type }}{% endif %}.</p>

    <div class="invite-card">
      <h2>{{ team_name }}</h2>
      <p>{{ team_description }}</p>
      <a href="{{ invite_url }}" class="button">Accept Invitation</a>
    </div>

    <h3>About {{ team_name }}</h3>
    <p>{{ team_details }}</p>

    <h3>Team Members</h3>
    <ul>
      {% for member in team_members %}
      <li>{{ member.name }} ({{ member.role }})</li>
      {% endfor %}
    </ul>

    <h3>Next Steps</h3>
    <ol>
      <li>Click the accept button above</li>
      <li>Set up your profile</li>
      <li>Start collaborating with the team</li>
    </ol>

    <p>
      This invitation will expire on <strong>{{ expiration_date }}</strong>. If you have any questions,
      contact {{ inviter.name }} at <a href="mailto:{{ inviter.email }}">{{ inviter.email }}</a>.
    </p>

    <p>Best regards,<br>
    The {{ platform_name }} Team</p>
  </div>
</body>
</html>
"""

context = %{
  "platform_name" => "CollabHub",
  "invited_user" => %{"name" => "Emma"},
  "inviter" => %{
    "name" => "Frank",
    "email" => "frank@example.com"
  },
  "team_name" => "Product Team",
  "team_type" => "Product Manager",
  "team_description" => "Building amazing products together",
  "team_details" => "Our product team is responsible for creating innovative solutions for our users.",
  "team_members" => [
    %{"name" => "Frank", "role" => "Team Lead"},
    %{"name" => "Grace", "role" => "Designer"},
    %{"name" => "Henry", "role" => "Developer"}
  ],
  "invite_url" => "https://example.com/accept-invite?token=abc123",
  "expiration_date" => "2024-11-29"
}

{:ok, email_html} = Mau.render(template, context)
```

---

## See Also

- [Report Generation](report-generation.md) - Data report examples
- [Template Language Reference](../reference/template-language.md) - Template language reference
- [Filters Guide](../guides/filters.md) - Using filters for formatting
