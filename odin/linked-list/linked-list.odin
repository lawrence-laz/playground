
// G VSCode "debug", "run" buttons for methods pretty nice

package main

import "core:fmt"
import "core:strings"
import "core:testing"

// main :: proc() {
// 	t := testing.T{}
// 	test_linked_list(&t)

// 	// if TEST_fail > 0 {
// 	// 	os.exit(1)
// 	// }
// }

@test
test_linked_list :: proc(t: ^testing.T) {
	list := new(LinkedList(i32))
	append(list, 1)
	append(list, 2)
	append(list, 3)

	testing.expect(t, list.first.value == 1, "first element should be 1")
	testing.expect(t, list.first.next.value == 2, "second element should be 2")
	testing.expect(t, list.first.next.next.value == 3, "third element should be 3")
	
	remove(list, 2)
	testing.expect(t, list.first.next.value == 3, "second element should be 3")
}

Node :: struct($T: typeid) {
	next:  ^Node(T),
	prev:  ^Node(T),
	value: T,
}

LinkedList :: struct($T: typeid) {
	first:  ^Node(T),
	last:   ^Node(T),
	length: uint,
}

append :: proc(list: ^LinkedList($T), item: T) {
	node := new(Node(T))
	node.prev = list.last
	node.value = item
	if list.first == nil {
		list.first = node
	} else {
		list.last.next = node
	}
	list.last = node
}

remove :: proc(list: ^LinkedList($T), item: T) -> bool {
	current_node := list.first
	for (current_node != nil) {
		if (current_node.value == item) {
			fmt.print("Remove found ", current_node.value, "=", item, "\n")
			if (list.first == current_node) {
				list.first = current_node.next
			} else {
				current_node.prev.next = current_node.next
			}
			list^.length -= 1
			return true
		}
		current_node = current_node.next
	}
	return false
}
