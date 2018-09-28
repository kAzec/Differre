## Differre

Pure Swift generic collection diff algorithm implementation base on Paul Heckel's diff algorithm.

### Examples

- Diffing two strings

```swift
var oldString = "åƒåß©©©åßasfa"
let newString = "😉ååß©åßas🤩🤩fa"

OrderedDiffResult(context: DiffContext(from: oldString, to: newString)).apply(to: &oldString)

XCTAssert(oldString == newString)
```

- Perform custom diff actions

  You can conform to `protocol DiffChangesApplier` to perform custom actions alongside with the process of diffing.

  For example, for updating one section in a `UITableView` by simply inserting and deleting rows, you can use:

  ```swift
  struct TableViewSectionUpdater<T> : DiffChangesApplier {
    typealias Index = Int

    let tableView: UITableView
    let sectionIndex: Int
    let rowAnimation: UITableView.RowAnimation

    mutating func applyDeletion(at index: Int) {
        tableView.deleteRows(at: [IndexPath(row: index, section: sectionIndex)], with: rowAnimation)
    }

    mutating func applyInsertion(_ element: T, at index: Int) {
        tableView.insertRows(at: [IndexPath(row: index, section: sectionIndex)], with: rowAnimation)
    }

    mutating func applyUpdateOrMove(
        _ oldElement: T,
        at oldIndex: Int,
        to newElement: T,
        at newIndex: Int,
        updated: Bool,
        moved: Bool
    ) {
        applyDeletion(at: oldIndex)
        applyInsertion(newElement, at: newIndex)
    }
  }
  ```

  And to use it:

  ```swift
  let updater = TableViewSectionUpdater(...)

  tableView.performBatchUpdates({
      let updater = TableViewSectionUpdater<RowModel>(...)
      updater.applyDiff(with: DiffContext(from: oldRowModels, to: newRowModels))
  }, completion: nil)

  ```

### LICENSE

[MIT](LICENSE)
