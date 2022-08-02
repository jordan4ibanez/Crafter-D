module entity.item.item;

import entity.entity;

// All items implement Entity, even in your inventory
public class Item : Entity {

    // For now, all items will utilize a string literal as the stack
    private string stack;

    // The amount of the item inside the stack
    private ubyte count;

    this(string newStack, ubyte newCount) {
        this.stack = newStack;
        this.count = newCount;
    }

    // Boilerplate

    // Stack is a one way switch, can only be assigned for now
    string getStack() {
        return this.stack;
    }
    ubyte getCount() {
        return this.count;
    }
    void setCount(ubyte newCount) {
        this.count = newCount;
    }
}