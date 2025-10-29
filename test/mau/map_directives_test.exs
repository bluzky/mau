defmodule Mau.MapDirectivesTest do
  use ExUnit.Case
  doctest Mau.MapDirectives

  describe "#map directive" do
    test "maps over a collection with $loop context" do
      input = %{
        items: %{
          "#map" => [
            "{{$items}}",
            %{
              name: "{{$loop.item.name}}",
              sku: "{{$loop.item.sku}}"
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

    test "handles nested property access in $loop.item" do
      input = %{
        users: %{
          "#map" => [
            "{{$users}}",
            %{
              full_name: "{{$loop.item.profile.firstName}} {{$loop.item.profile.lastName}}",
              email: "{{$loop.item.contact.email}}"
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
          "#map" => [
            "{{$items}}",
            %{name: "{{$loop.item.name}}"}
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
          "#map" => [
            "{{$items}}",
            %{name: "{{$loop.item.name}}"}
          ]
        }
      }

      context = %{"$items" => nil}

      expected = %{items: []}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "can access context variables alongside $loop.item" do
      input = %{
        items: %{
          "#map" => [
            "{{$items}}",
            %{
              product: "{{$loop.item.name}}",
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

    test "supports nested #map directives" do
      input = %{
        categories: %{
          "#map" => [
            "{{$categories}}",
            %{
              category: "{{$loop.item.name}}",
              products: %{
                "#map" => [
                  "{{$loop.item.products}}",
                  %{
                    name: "{{$loop.item.name}}",
                    # Don't use template for price to preserve type
                    price: "{{$loop.item.price}}"
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

    test "provides index access via $loop.index" do
      input = %{
        items: %{
          "#map" => [
            "{{$items}}",
            %{
              name: "{{$loop.item.name}}",
              position: "{{$loop.index}}",
              is_first: "{{$loop.index == 0}}",
              is_even: "{{$loop.index % 2 == 0}}"
            }
          ]
        }
      }

      context = %{
        "$items" => [
          %{"name" => "Alice"},
          %{"name" => "Bob"},
          %{"name" => "Charlie"}
        ]
      }

      expected = %{
        items: [
          %{name: "Alice", position: 0, is_first: true, is_even: true},
          %{name: "Bob", position: 1, is_first: false, is_even: false},
          %{name: "Charlie", position: 2, is_first: false, is_even: true}
        ]
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "provides parent loop access via $loop.parentloop" do
      input = %{
        departments: %{
          "#map" => [
            "{{$departments}}",
            %{
              dept_name: "{{$loop.item.name}}",
              dept_index: "{{$loop.index}}",
              employees: %{
                "#map" => [
                  "{{$loop.item.employees}}",
                  %{
                    emp_name: "{{$loop.item.name}}",
                    emp_index: "{{$loop.index}}",
                    department: "{{$loop.parentloop.item.name}}",
                    department_index: "{{$loop.parentloop.index}}"
                  }
                ]
              }
            }
          ]
        }
      }

      context = %{
        "$departments" => [
          %{
            "name" => "Engineering",
            "employees" => [
              %{"name" => "Alice"},
              %{"name" => "Bob"}
            ]
          },
          %{
            "name" => "Sales",
            "employees" => [
              %{"name" => "Carol"}
            ]
          }
        ]
      }

      expected = %{
        departments: [
          %{
            dept_name: "Engineering",
            dept_index: 0,
            employees: [
              %{emp_name: "Alice", emp_index: 0, department: "Engineering", department_index: 0},
              %{emp_name: "Bob", emp_index: 1, department: "Engineering", department_index: 0}
            ]
          },
          %{
            dept_name: "Sales",
            dept_index: 1,
            employees: [
              %{emp_name: "Carol", emp_index: 0, department: "Sales", department_index: 1}
            ]
          }
        ]
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "handles invalid arguments gracefully" do
      input = %{
        items: %{
          "#map" => "not a list"
        }
      }

      context = %{}

      # When args is not a list, it's treated as a regular map key
      expected = %{items: %{"#map" => "not a list"}}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "returns empty list for non-list collection" do
      input = %{
        items: %{
          "#map" => [
            "{{$items}}",
            %{name: "{{$loop.item.name}}"}
          ]
        }
      }

      context = %{"$items" => "not a list"}

      expected = %{items: []}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end
  end

  describe "#merge directive" do
    test "merges two maps together" do
      input = %{
        user: %{
          "#merge" => [
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
          "#merge" => [
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
          "#merge" => [
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
          "#merge" => []
        }
      }

      context = %{}

      # When args is an empty list, it's treated as a regular map key (length must be > 0)
      expected = %{result: %{"#merge" => []}}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "ignores non-map values in merge" do
      input = %{
        result: %{
          "#merge" => [
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
          "#merge" => [
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
          "#merge" => "not a list"
        }
      }

      context = %{}

      # When args is not a list, it's treated as a regular map key
      expected = %{result: %{"#merge" => "not a list"}}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end
  end

  describe "combined directives" do
    test "#map and #merge work together" do
      input = %{
        enriched_users: %{
          "#map" => [
            "{{$users}}",
            %{
              "#merge" => [
                "{{$loop.item}}",
                %{
                  display_name: "{{$loop.item.name}}",
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
          "#map" => [
            "{{$departments}}",
            %{
              "#merge" => [
                "{{$loop.item}}",
                %{
                  employees: %{
                    "#map" => [
                      "{{$loop.item.staff}}",
                      %{
                        name: "{{$loop.item.name}}",
                        dept: "{{$loop.item.department}}"
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

  describe "#if directive" do
    test "renders true template when condition is truthy" do
      input = %{
        status: %{
          "#if" => [
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
          "#if" => [
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
          "#if" => [
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
            "#if" => [
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
            "#if" => [
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
          "#if" => "invalid"
        }
      }

      context = %{}
        # When args is not a list, it's treated as a regular map key
      expected = %{result: %{"#if" => "invalid"}}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end
  end

  describe "#filter directive" do
    test "filters collection based on condition" do
      input = %{
        active_users: %{
          "#filter" => [
            "{{$users}}",
            "{{$loop.item.status == 'active'}}"
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
          "#filter" => [
            "{{$items}}",
            "{{$loop.item.price > 100}}"
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
          "#filter" => [
            "{{$items}}",
            "{{$loop.item.active}}"
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
          "#filter" => [
            "{{$items}}",
            "{{$loop.item.active}}"
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
          "#filter" => "invalid"
        }
      }

      context = %{}

      expected = %{result: %{"#filter" => "invalid"}}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end
  end

  
  describe "#pipe directive" do
    test "pipes value through filter and map" do
      input = %{
        result: %{
          "#pipe" => [
            "{{$users}}",
            [
              %{"#filter" => "{{$loop.item.active}}"},
              %{"#map" => %{name: "{{$loop.item.name}}"}}
            ]
          ]
        }
      }

      context = %{
        "$users" => [
          %{"name" => "John", "active" => true},
          %{"name" => "Jane", "active" => false},
          %{"name" => "Bob", "active" => true}
        ]
      }

      expected = %{
        result: [
          %{name: "John"},
          %{name: "Bob"}
        ]
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "pipes value through map and merge" do
      input = %{
        enriched: %{
          "#pipe" => [
            "{{$items}}",
            [
              %{"#map" => %{name: "{{$loop.item.name}}"}},
              %{"#map" => %{
                "#merge" => [
                  "{{$loop.item}}",
                  %{company: "{{$company}}"}
                ]
              }}
            ]
          ]
        }
      }

      context = %{
        "$items" => [
          %{"name" => "Product 1"},
          %{"name" => "Product 2"}
        ],
        "$company" => "Acme Corp"
      }

      expected = %{
        enriched: [
          %{name: "Product 1", company: "Acme Corp"},
          %{name: "Product 2", company: "Acme Corp"}
        ]
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "pipes single map through merge and pick" do
      input = %{
        user: %{
          "#pipe" => [
            "{{$user}}",
            [
              %{"#merge" => %{status: "active"}},
              %{"#merge" => %{last_login: "2024-01-15"}},
              %{"#pick" => ["name", "email", :status, :last_login]}
            ]
          ]
        }
      }

      context = %{
        "$user" => %{
          "name" => "John",
          "email" => "john@example.com",
          "age" => 30,
          "password" => "secret"
        }
      }

      expected = %{
        user: %{
          "name" => "John",
          "email" => "john@example.com",
          status: "active",
          last_login: "2024-01-15"
        }
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "handles empty directive list" do
      input = %{
        result: %{
          "#pipe" => [
            "{{$value}}",
            []
          ]
        }
      }

      context = %{"$value" => "unchanged"}

      expected = %{result: "unchanged"}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "pipes with conditional logic" do
      input = %{
        result: %{
          "#pipe" => [
            "{{$items}}",
            [
              %{"#filter" => "{{$loop.item.price > 100}}"},
              %{"#map" => %{
                "#if" => [
                  "{{$loop.item.premium}}",
                  %{name: "{{$loop.item.name}}", badge: "premium"},
                  %{name: "{{$loop.item.name}}", badge: "standard"}
                ]
              }}
            ]
          ]
        }
      }

      context = %{
        "$items" => [
          %{"name" => "Laptop", "price" => 999, "premium" => true},
          %{"name" => "Book", "price" => 20, "premium" => false},
          %{"name" => "Phone", "price" => 599, "premium" => false}
        ]
      }

      expected = %{
        result: [
          %{name: "Laptop", badge: "premium"},
          %{name: "Phone", badge: "standard"}
        ]
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "accesses context variables within pipe" do
      input = %{
        result: %{
          "#pipe" => [
            "{{$products}}",
            [
              %{"#map" => %{
                name: "{{$loop.item.name}}",
                company: "{{$company}}"
              }}
            ]
          ]
        }
      }

      context = %{
        "$products" => [
          %{"name" => "Widget"},
          %{"name" => "Gadget"}
        ],
        "$company" => "Acme Corp"
      }

      expected = %{
        result: [
          %{name: "Widget", company: "Acme Corp"},
          %{name: "Gadget", company: "Acme Corp"}
        ]
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "complex pipe with multiple transformations" do
      input = %{
        result: %{
          "#pipe" => [
            "{{$users}}",
            [
              %{"#filter" => "{{$loop.item.status == 'active'}}"},
              %{"#map" => %{
                id: "{{$loop.item.id}}",
                name: "{{$loop.item.name}}",
                email: "{{$loop.item.email}}"
              }},
              %{"#filter" => "{{$loop.item.id > 1}}"}
            ]
          ]
        }
      }

      context = %{
        "$users" => [
          %{"id" => 1, "name" => "John", "email" => "john@example.com", "status" => "active"},
          %{"id" => 2, "name" => "Jane", "email" => "jane@example.com", "status" => "active"},
          %{"id" => 3, "name" => "Bob", "email" => "bob@example.com", "status" => "inactive"}
        ]
      }

      expected = %{
        result: [
          %{id: 2, name: "Jane", email: "jane@example.com"}
        ]
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "handles invalid arguments gracefully" do
      input = %{
        result: %{
          "#pipe" => "invalid"
        }
      }

      context = %{}

      expected = %{result: %{"#pipe" => "invalid"}}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "handles invalid directives list gracefully" do
      input = %{
        result: %{
          "#pipe" => ["{{$value}}", "not a list"]
        }
      }

      context = %{"$value" => "test"}

      # When directives arg is not a list, it's treated as a regular map key
      # The template gets rendered
      expected = %{result: %{"#pipe" => ["test", "not a list"]}}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end

    test "nested pipes work independently" do
      input = %{
        result: %{
          "#pipe" => [
            "{{$departments}}",
            [
              %{"#map" => %{
                dept: "{{$loop.item.name}}",
                active_staff: %{
                  "#pipe" => [
                    "{{$loop.item.employees}}",
                    [
                      %{"#filter" => "{{$loop.item.active}}"},
                      %{"#map" => %{name: "{{$loop.item.name}}"}}
                    ]
                  ]
                }
              }}
            ]
          ]
        }
      }

      context = %{
        "$departments" => [
          %{
            "name" => "Engineering",
            "employees" => [
              %{"name" => "Alice", "active" => true},
              %{"name" => "Bob", "active" => false}
            ]
          },
          %{
            "name" => "Sales",
            "employees" => [
              %{"name" => "Carol", "active" => true}
            ]
          }
        ]
      }

      expected = %{
        result: [
          %{
            dept: "Engineering",
            active_staff: [%{name: "Alice"}]
          },
          %{
            dept: "Sales",
            active_staff: [%{name: "Carol"}]
          }
        ]
      }

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end
  end

  describe "#pick directive" do
    test "extracts specific keys from map" do
      input = %{
        user_info: %{
          "#pick" => [
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
          "#pick" => [
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
          "#pick" => [
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
          "#pick" => [
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
          "#pick" => "invalid"
        }
      }

      context = %{}

      expected = %{result: %{"#pick" => "invalid"}}

      assert {:ok, ^expected} = Mau.render_map(input, context)
    end
  end
end
