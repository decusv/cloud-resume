describe("GitHub Icon Interaction", () => {
  it("verifies the GitHub link without navigating", () => {
    cy.visit("http://tmriabovas.tech", {
      timeout: 10000,
    });

    // Check the href attribute of the GitHub link
    cy.get('a[href*="github.com"]')
      .should("exist")
      .should("be.visible")
      .invoke("attr", "href")
      .should("equal", "https://github.com/decusv"); // Replace with the expected URL
  });
});

describe("LinkedIn Icon Interaction", () => {
  it("verifies the LinkedIn link without navigating", () => {
    cy.visit("http://tmriabovas.tech", {
      timeout: 10000,
    });

    // Check the href attribute of the LinkedIn link
    cy.get('a[href*="linkedin.com"]')
      .should("exist")
      .should("be.visible")
      .invoke("attr", "href")
      .should("equal", "https://linkedin.com/in/tomas-riabovas-584251182"); // Replace with the expected URL
  });
});

describe("Profile Icon and Visitor Count Interaction", () => {
  it("verifies the profile icon is loading and the number of visitors is displayed", () => {
    cy.visit("http://tmriabovas.tech", {
      timeout: 10000,
    });

    // Check if the profile icon is visible
    cy.get("img.profile-pic") // Replace with the actual selector for the profile icon
      .should("exist")
      .should("be.visible");

    // Check if the number of visitors is displayed
    cy.get(".visitor-counter") // Replace with the actual selector for the visitor count
      .should("exist")
      .should("be.visible")
      .and("not.be.empty"); // Ensure it's not empty
  });
});
