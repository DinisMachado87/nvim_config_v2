#include "{{CLASS_NAME}}.hpp"

// Protected inheritance constructor
{{CLASS_NAME}}::{{CLASS_NAME}}() {}

// Public constructors and destructors
{{CLASS_NAME}}::{{CLASS_NAME}}(const {{CLASS_NAME}}& other) {}

{{CLASS_NAME}}::~{{CLASS_NAME}}() {}

{{CLASS_NAME}}& {{CLASS_NAME}}::operator=(const {{CLASS_NAME}}& other) {
	if (this == &other) return *this;
	return *this;
}

// Public Methods
