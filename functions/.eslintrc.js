module.exports = {
  env: {
    es6: true,
    node: true,
  },
  parserOptions: {
    "ecmaVersion": 2020,
  },
  extends: [
    "eslint:recommended",
    "google",
  ],
  rules: {
    "no-restricted-globals": ["error", "name", "length"],
    "prefer-arrow-callback": "error",
    "quotes": ["error", "double", {"allowTemplateLiterals": true}],
    "max-len": ["error", {"code": 120}],
    "indent": ["error", 2],
    "object-curly-spacing": ["error", "never"],
    "require-jsdoc": "off",
    "linebreak-style": "off", // Allow Windows CRLF
  },
  overrides: [
    {
      files: ["**/*.spec.*"],
      env: {
        jest: true,
      },
      rules: {},
    },
  ],
  globals: {},
};
