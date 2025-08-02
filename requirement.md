✅ Features & Functional Scope
1. Order ID Input & Fetching

    Input Field: Accepts a valid Shopify Order ID.

    Fetch Button: Triggers a request to the Shopify Admin API to retrieve the order data.

    Validation:

        If Order ID is invalid or order not found, show error message.

        Disable fetch if input is empty.

2. Display Order Details

    Product List UI: Show all products in the order with:

        Product title

        Quantity

        SKU

    Editable Fields (per product):

        delivery_date (Date input)

        delivery_slot (Dropdown or text input)

3. Editing Metafields

    Editable inputs should be pre-filled if metafields already exist.

    All metafields must be namespace- and key-consistent (e.g., namespace: "custom", keys: "delivery_date", "delivery_slot").

4. Save Changes

    Save Button: Validates inputs and updates metafields using the Shopify Admin API.

    API should update each product’s line-item metafields for the given order.

    Success Message: Confirmation after successful update.

    Error Handling: Display appropriate message if the update fails.
