// Tests in this file are NOT run in the PR pipeline. They are run in the continuous testing pipeline along with the ones in pr_test.go
package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

// Test the DA when using IBM owned encryption keys
func TestRunStandardSolutionIBMKeys(t *testing.T) {
	t.Parallel()

	region := "us-south"

	options := testhelper.TestOptionsDefault(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  fullyConfigurableSolutionTerraformDir,
		Region:        region,
		Prefix:        "valkey-key",
		ResourceGroup: resourceGroup,
	})

	// Note: Version hardcoded to 9.0 because icd-versions API doesn't list Valkey
	valkeyVersion := "9.0"
	options.TerraformVars = map[string]interface{}{
		"valkey_version":               valkeyVersion,
		"region":                       region,
		"provider_visibility":          "private", // Valkey only supports private endpoints
		"existing_resource_group_name": resourceGroup,
		"prefix":                       options.Prefix,
		"deletion_protection":          false,
	}

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}
