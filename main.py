def main():
    print("Hello from cutdeck!")

    # Test DaggyD installation
    from DaggyD.pregel_core import pregel, add_channel, add_node, run

    # Create a simple counter graph to verify DaggyD works
    p = pregel()
    p = add_channel(p, "count", "LastValue", initial_value=0)

    def increment(inputs):
        val = inputs.get("count", 0)
        return {"out": val + 1} if val < 5 else None

    p = add_node(p, "counter", increment,
        subscribe_to=["count"],
        write_to={"out": "count"})

    result = run(p)
    
    assert result["count"] == 5, f"Expected count=5, got {result['count']}"
    print(f"DaggyD test passed! Counter reached: {result['count']}")


if __name__ == "__main__":
    main()
