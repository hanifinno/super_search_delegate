# 🔍 Super Search Delegate

[![Pub Version](https://img.shields.io/pub/v/super_search_delegate)](https://pub.dev/packages/super_search_delegate)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

A **highly customizable**, **easy-to-use**, and **generic search delegate** for Flutter. Works with any data model, supports both property-based and custom filtering, and gives you full control over the search result UI.

---

## ✨ Key Features

- ✅ Search through **any data model** (`String`, `Map`, custom class, etc.)
- 🎯 Search by **specific properties** or use **custom filtering logic**
- 🖌️ Fully customizable result UI using your own widgets
- ⚡ Optimized for performance, even with large datasets
- 📱 Keyboard and accessibility friendly

---

## 🔧 Installation

Add the latest version to your `pubspec.yaml`:

```yaml
dependencies:
  super_search_delegate: ^1.0.5
```

---

## 💻 Usage

```dart
await SuperSearchDelegate.show<String>(
  context: context,
  config: SearchConfig<String>(
    items: ['Apple', 'Banana', 'Mango', 'Orange'],
    itemBuilder: (context, item, query) => ListTile(title: Text(item)),
    propertySelector: (item) => [item],
    onItemSelected: (item) => print('You selected: $item'),
  ),
);
```

---

## 🧩 Search with Custom Model

```dart
class Fruit {
  final String id;
  final String name;

  Fruit(this.id, this.name);
}

final fruits = [
  Fruit('001', 'Apple'),
  Fruit('002', 'Banana'),
  Fruit('003', 'Mango'),
];

await SuperSearchDelegate.show<Fruit>(
  context: context,
  config: SearchConfig<Fruit>(
    items: fruits,
    itemBuilder: (context, item, query) => ListTile(
      title: Text(item.name),
      subtitle: Text('ID: ${item.id}'),
    ),
    propertySelector: (item) => [item.id, item.name],
    onItemSelected: (item) => print('Selected: ${item.name}'),
  ),
);
``` 
----

## ⚙️ API Reference

| Property           | Type                       | Description                                                |
| ------------------ | -------------------------- | ---------------------------------------------------------- |
| `items`            | `List<T>`                  | The full list of items to search through.                  |
| `itemBuilder`      | `ItemBuilder<T>`           | Widget builder for each filtered item.                     |
| `propertySelector` | `List<String> Function(T)` | Optional. Defines which properties are searchable.         |
| `customFilter`     | `bool Function(T, String)` | Optional. Use custom logic to filter items.                |
| `searchFieldLabel` | `String`                   | Placeholder for the search bar. Defaults to `"Search..."`. |
| `noResultsWidget`  | `Widget?`                  | Widget shown when no results are found.                    |
| `onItemSelected`   | `void Function(T)`         | Callback triggered when an item is tapped.                 |

---

## 🙌 Maintained and Powered by 
* 📧 **[hanifuddin.dev@gmail.com](mailto:hanifuddin.dev@gmail.com)**
* 📧 **[mirza.dev25@gmail.com](mailto:mirza.dev25@gmail.com)**