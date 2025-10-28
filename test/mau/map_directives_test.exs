defmodule Mau.MapDirectivesTest do
  use ExUnit.Case
  doctest Mau.MapDirectives

  describe "_.forEach directive" do
    test "maps over a collection with $self context" do
      input = %{
        items: %{
          "_.forEach" => [
            "{{$items}}",
            %{
              name: "{{$self.name}}",
              sku: "{{$self.sku}}"
            }
          ]
        }
      }

      context = %{
        "$items" => [
          %{"name" => "Product 1", "sku" => "SKU001"},
          %{"name" => "Product 2", "sku" => "SKU002"}
        ]
      }

      expected = %{
        items: [
          %{name: "Product 1", sku: "SKU001"},
          %{name: "Product 2", sku: "SKU002"}
        ]
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "handles nested property access in $self" do
      input = %{
        users: %{
          "_.forEach" => [
            "{{$users}}",
            %{
              full_name: "{{$self.profile.firstName}} {{$self.profile.lastName}}",
              email: "{{$self.contact.email}}"
            }
          ]
        }
      }

      context = %{
        "$users" => [
          %{
            "profile" => %{"firstName" => "John", "lastName" => "Doe"},
            "contact" => %{"email" => "john@example.com"}
          },
          %{
            "profile" => %{"firstName" => "Jane", "lastName" => "Smith"},
            "contact" => %{"email" => "jane@example.com"}
          }
        ]
      }

      expected = %{
        users: [
          %{full_name: "John Doe", email: "john@example.com"},
          %{full_name: "Jane Smith", email: "jane@example.com"}
        ]
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "handles empty collection" do
      input = %{
        items: %{
          "_.forEach" => [
            "{{$items}}",
            %{name: "{{$self.name}}"}
          ]
        }
      }

      context = %{"$items" => []}

      expected = %{items: []}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "handles nil collection" do
      input = %{
        items: %{
          "_.forEach" => [
            "{{$items}}",
            %{name: "{{$self.name}}"}
          ]
        }
      }

      context = %{"$items" => nil}

      expected = %{items: []}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "can access context variables alongside $self" do
      input = %{
        items: %{
          "_.forEach" => [
            "{{$items}}",
            %{
              product: "{{$self.name}}",
              company: "{{$company}}"
            }
          ]
        }
      }

      context = %{
        "$items" => [
          %{"name" => "Widget"},
          %{"name" => "Gadget"}
        ],
        "$company" => "Acme Corp"
      }

      expected = %{
        items: [
          %{product: "Widget", company: "Acme Corp"},
          %{product: "Gadget", company: "Acme Corp"}
        ]
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "supports nested _.forEach directives" do
      input = %{
        categories: %{
          "_.forEach" => [
            "{{$categories}}",
            %{
              category: "{{$self.name}}",
              products: %{
                "_.forEach" => [
                  "{{$self.products}}",
                  %{
                    name: "{{$self.name}}",
                    # Don't use template for price to preserve type
                    price: "{{$self.price}}"
                  }
                ]
              }
            }
          ]
        }
      }

      context = %{
        "$categories" => [
          %{
            "name" => "Electronics",
            "products" => [
              %{"name" => "Phone", "price" => 999},
              %{"name" => "Laptop", "price" => 1299}
            ]
          },
          %{
            "name" => "Books",
            "products" => [
              %{"name" => "Novel", "price" => 15}
            ]
          }
        ]
      }

      # Type preservation keeps numbers as numbers when using {{}} with preserve_types: true
      # But we render with template so they become strings
      expected = %{
        categories: [
          %{
            category: "Electronics",
            products: [
              %{name: "Phone", price: 999},
              %{name: "Laptop", price: 1299}
            ]
          },
          %{
            category: "Books",
            products: [
              %{name: "Novel", price: 15}
            ]
          }
        ]
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "handles invalid arguments gracefully" do
      input = %{
        items: %{
          "_.forEach" => "not a list"
        }
      }

      context = %{}

      # When args is not a list, it's treated as a regular map key
      expected = %{items: %{"_.forEach" => "not a list"}}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "returns empty list for non-list collection" do
      input = %{
        items: %{
          "_.forEach" => [
            "{{$items}}",
            %{name: "{{$self.name}}"}
          ]
        }
      }

      context = %{"$items" => "not a list"}

      expected = %{items: []}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end
  end

  describe "_.merge directive" do
    test "merges two maps together" do
      input = %{
        user: %{
          "_.merge" => [
            "{{$original}}",
            %{age: 20, status: "active"}
          ]
        }
      }

      context = %{
        "$original" => %{"name" => "John", "age" => 18}
      }

      expected = %{
        user: %{
          "name" => "John",
          "age" => 18,  # Original string key preserved
          age: 20,       # New atom key added
          status: "active"
        }
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "later values override earlier values" do
      input = %{
        config: %{
          "_.merge" => [
            %{a: 1, b: 2, c: 3},
            %{b: 20, d: 4},
            %{c: 30, e: 5}
          ]
        }
      }

      context = %{}

      expected = %{
        config: %{
          a: 1,
          b: 20,
          c: 30,
          d: 4,
          e: 5
        }
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "merges maps from context variables" do
      input = %{
        result: %{
          "_.merge" => [
            "{{$base}}",
            "{{$override}}"
          ]
        }
      }

      context = %{
        "$base" => %{"name" => "John", "age" => 25},
        "$override" => %{"age" => 30, "city" => "NYC"}
      }

      expected = %{
        result: %{
          "name" => "John",
          "age" => 30,
          "city" => "NYC"
        }
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "handles empty merge list" do
      input = %{
        result: %{
          "_.merge" => []
        }
      }

      context = %{}

      # When args is an empty list, it's treated as a regular map key (length must be > 0)
      expected = %{result: %{"_.merge" => []}}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "ignores non-map values in merge" do
      input = %{
        result: %{
          "_.merge" => [
            %{a: 1},
            "not a map",
            %{b: 2},
            42,
            %{c: 3}
          ]
        }
      }

      context = %{}

      expected = %{
        result: %{
          a: 1,
          b: 2,
          c: 3
        }
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "merges with nested template rendering" do
      input = %{
        user: %{
          "_.merge" => [
            "{{$user}}",
            %{
              full_name: "{{$user.firstName}} {{$user.lastName}}",
              status: "active"
            }
          ]
        }
      }

      context = %{
        "$user" => %{
          "firstName" => "John",
          "lastName" => "Doe",
          "age" => 25
        }
      }

      expected = %{
        user: %{
          "firstName" => "John",
          "lastName" => "Doe",
          "age" => 25,
          full_name: "John Doe",
          status: "active"
        }
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "handles invalid arguments gracefully" do
      input = %{
        result: %{
          "_.merge" => "not a list"
        }
      }

      context = %{}

      # When args is not a list, it's treated as a regular map key
      expected = %{result: %{"_.merge" => "not a list"}}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end
  end

  describe "combined directives" do
    test "_.forEach and _.merge work together" do
      input = %{
        enriched_users: %{
          "_.forEach" => [
            "{{$users}}",
            %{
              "_.merge" => [
                "{{$self}}",
                %{
                  display_name: "{{$self.name}}",
                  company: "{{$company}}"
                }
              ]
            }
          ]
        }
      }

      context = %{
        "$users" => [
          %{"name" => "John", "age" => 30},
          %{"name" => "Jane", "age" => 25}
        ],
        "$company" => "Acme Corp"
      }

      expected = %{
        enriched_users: [
          %{
            "name" => "John",
            "age" => 30,
            display_name: "John",
            company: "Acme Corp"
          },
          %{
            "name" => "Jane",
            "age" => 25,
            display_name: "Jane",
            company: "Acme Corp"
          }
        ]
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "complex nested directives with multiple levels" do
      input = %{
        departments: %{
          "_.forEach" => [
            "{{$departments}}",
            %{
              "_.merge" => [
                "{{$self}}",
                %{
                  employees: %{
                    "_.forEach" => [
                      "{{$self.staff}}",
                      %{
                        name: "{{$self.name}}",
                        dept: "{{$self.department}}"
                      }
                    ]
                  }
                }
              ]
            }
          ]
        }
      }

      context = %{
        "$departments" => [
          %{
            "name" => "Engineering",
            "staff" => [
              %{"name" => "Alice", "department" => "Engineering"},
              %{"name" => "Bob", "department" => "Engineering"}
            ]
          }
        ]
      }

      expected = %{
        departments: [
          %{
            "name" => "Engineering",
            "staff" => [
              %{"name" => "Alice", "department" => "Engineering"},
              %{"name" => "Bob", "department" => "Engineering"}
            ],
            employees: [
              %{name: "Alice", dept: "Engineering"},
              %{name: "Bob", dept: "Engineering"}
            ]
          }
        ]
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end
  end

  describe "_.if directive" do
    test "renders true template when condition is truthy" do
      input = %{
        status: %{
          "_.if" => [
            "{{$user.is_active}}",
            %{message: "User is active", badge: "online"}
          ]
        }
      }

      context = %{
        "$user" => %{"is_active" => true}
      }

      expected = %{
        status: %{message: "User is active", badge: "online"}
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "renders nil when condition is falsy and no else template" do
      input = %{
        status: %{
          "_.if" => [
            "{{$user.is_active}}",
            %{message: "User is active", badge: "online"}
          ]
        }
      }

      context = %{
        "$user" => %{"is_active" => false}
      }

      expected = %{
        status: nil
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "renders false template when condition is falsy with else clause" do
      input = %{
        status: %{
          "_.if" => [
            "{{$user.is_active}}",
            %{message: "User is active", badge: "online"},
            %{message: "User is inactive", badge: "offline"}
          ]
        }
      }

      context = %{
        "$user" => %{"is_active" => false}
      }

      expected = %{
        status: %{message: "User is inactive", badge: "offline"}
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "handles various truthy values" do
      input_values = [true, "yes", 1, [1], %{a: 1}, "non-empty string"]

      Enum.each(input_values, fn value ->
        input = %{
          result: %{
            "_.if" => [
              value,
              %{success: true},
              %{success: false}
            ]
          }
        }

        context = %{}
        expected = %{result: %{success: true}}

        assert {:ok, ^expected} = Mau.render_map(input, context)
      end)
    end

    test "handles various falsy values" do
      falsy_values = [false, nil, [], {}, ""]

      Enum.each(falsy_values, fn value ->
        input = %{
          result: %{
            "_.if" => [
              value,
              %{success: true},
              %{success: false}
            ]
          }
        }

        context = %{}
        expected = %{result: %{success: false}}

        assert {:ok, ^expected} = Mau.render_map(input, context)
      end)
    end

    test "handles invalid arguments gracefully" do
      input = %{
        result: %{
          "_.if" => "invalid"
        }
      }

      context = %{}
        # When args is not a list, it's treated as a regular map key
      expected = %{result: %{"_.if" => "invalid"}}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end
  end

  describe "_.filter directive" do
    test "filters collection based on condition" do
      input = %{
        active_users: %{
          "_.filter" => [
            "{{$users}}",
            "{{$self.status == 'active'}}"
          ]
        }
      }

      context = %{
        "$users" => [
          %{"name" => "John", "status" => "active"},
          %{"name" => "Jane", "status" => "inactive"},
          %{"name" => "Bob", "status" => "active"}
        ]
      }

      expected = %{
        active_users: [
          %{"name" => "John", "status" => "active"},
          %{"name" => "Bob", "status" => "active"}
        ]
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "filters with numeric comparison" do
      input = %{
        expensive_items: %{
          "_.filter" => [
            "{{$items}}",
            "{{$self.price > 100}}"
          ]
        }
      }

      context = %{
        "$items" => [
          %{"name" => "Book", "price" => 20},
          %{"name" => "Laptop", "price" => 999},
          %{"name" => "Phone", "price" => 199}
        ]
      }

      expected = %{
        expensive_items: [
          %{"name" => "Laptop", "price" => 999},
          %{"name" => "Phone", "price" => 199}
        ]
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "handles empty collection" do
      input = %{
        filtered: %{
          "_.filter" => [
            "{{$items}}",
            "{{$self.active}}"
          ]
        }
      }

      context = %{"$items" => []}

      expected = %{filtered: []}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "handles nil collection" do
      input = %{
        filtered: %{
          "_.filter" => [
            "{{$items}}",
            "{{$self.active}}"
          ]
        }
      }

      context = %{"$items" => nil}

      expected = %{filtered: []}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "handles invalid arguments gracefully" do
      input = %{
        result: %{
          "_.filter" => "invalid"
        }
      }

      context = %{}

      expected = %{result: %{"_.filter" => "invalid"}}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end
  end

  describe "_.map directive" do
    test "extracts specific field from collection" do
      input = %{
        user_names: %{
          "_.map" => [
            "{{$users}}",
            "name"
          ]
        }
      }

      context = %{
        "$users" => [
          %{"name" => "John", "age" => 30},
          %{"name" => "Jane", "age" => 25},
          %{"name" => "Bob", "age" => 35}
        ]
      }

      expected = %{
        user_names: ["John", "Jane", "Bob"]
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "handles missing field with nil values" do
      input = %{
        emails: %{
          "_.map" => [
            "{{$users}}",
            "email"
          ]
        }
      }

      context = %{
        "$users" => [
          %{"name" => "John", "email" => "john@example.com"},
          %{"name" => "Jane"},  # No email field
          %{"name" => "Bob", "email" => "bob@example.com"}
        ]
      }

      expected = %{
        emails: ["john@example.com", nil, "bob@example.com"]
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "handles non-map items" do
      input = %{
        values: %{
          "_.map" => [
            "{{$items}}",
            "field"
          ]
        }
      }

      context = %{
        "$items" => [
          %{"field" => "value1"},
          "string item",
          42,
          %{"field" => "value2"}
        ]
      }

      expected = %{
        values: ["value1", nil, nil, "value2"]
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "handles empty collection" do
      input = %{
        names: %{
          "_.map" => [
            "{{$users}}",
            "name"
          ]
        }
      }

      context = %{"$users" => []}

      expected = %{names: []}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "handles invalid arguments gracefully" do
      input = %{
        result: %{
          "_.map" => "invalid"
        }
      }

      context = %{}

      expected = %{result: %{"_.map" => "invalid"}}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end
  end

  describe "_.pick directive" do
    test "extracts specific keys from map" do
      input = %{
        user_info: %{
          "_.pick" => [
            "{{$user}}",
            ["name", "email"]
          ]
        }
      }

      context = %{
        "$user" => %{
          "name" => "John",
          "email" => "john@example.com",
          "age" => 30,
          "password" => "secret",
          "address" => "123 Main St"
        }
      }

      expected = %{
        user_info: %{
          "name" => "John",
          "email" => "john@example.com"
        }
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "handles missing keys gracefully" do
      input = %{
        partial_info: %{
          "_.pick" => [
            "{{$user}}",
            ["name", "email", "phone", "age"]
          ]
        }
      }

      context = %{
        "$user" => %{
          "name" => "John",
          "age" => 30
          # email and phone are missing
        }
      }

      expected = %{
        partial_info: %{
          "name" => "John",
          "age" => 30
        }
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "handles empty keys list" do
      input = %{
        empty_result: %{
          "_.pick" => [
            "{{$user}}",
            []
          ]
        }
      }

      context = %{
        "$user" => %{"name" => "John", "email" => "john@example.com"}
      }

      expected = %{empty_result: %{}}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "handles non-map template result" do
      input = %{
        result: %{
          "_.pick" => [
            "{{$value}}",
            ["name"]
          ]
        }
      }

      context = %{"$value" => "not a map"}

      expected = %{result: %{}}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "handles invalid arguments gracefully" do
      input = %{
        result: %{
          "_.pick" => "invalid"
        }
      }

      context = %{}

      expected = %{result: %{"_.pick" => "invalid"}}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end
  end
end
