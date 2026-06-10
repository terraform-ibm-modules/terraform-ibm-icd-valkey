// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

// Use existing resource group
const resourceGroup = "geretain-test-valkey"

const basicExampleDir = "examples/basic"
const advancedExampleDir = "examples/advanced"

// Valkey Gen2 only supports private service endpoints, so tests must run via
// IBM Cloud Schematics (which executes inside IBM Cloud's network).

func setupOptions(t *testing.T, prefix string, dir string) *testschematic.TestSchematicOptions {
	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		Prefix:  prefix,
		TarIncludePatterns: []string{
			"*.tf",
			dir + "/*.tf",
		},
		TemplateFolder:         dir,
		Tags:                   []string{"test-schematic"},
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 90,
	})

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "region", Value: options.Region, DataType: "string"},
		{Name: "resource_group", Value: resourceGroup, DataType: "string"},
		{Name: "member_host_flavor", Value: "bx3d.4x20", DataType: "string"},
	}
	return options
}

func TestRunBasicExampleSchematics(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "valkey-basic", basicExampleDir)
	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}

func TestRunAdvancedExampleSchematics(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "valkey-adv", advancedExampleDir)
	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}

func TestRunUpgradeExampleSchematics(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "valkey-adv-upg", advancedExampleDir)
	options.CheckApplyResultForUpgrade = true

	err := options.RunSchematicUpgradeTest()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
	}
}
