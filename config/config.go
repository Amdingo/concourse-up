package config

import (
	"encoding/json"
	"fmt"
	"strings"

	"bitbucket.org/engineerbetter/concourse-up/util"
)

// Config represents a concourse-up configuration file
type Config struct {
	PublicKey                string `json:"public_key"`
	PrivateKey               string `json:"private_key"`
	Region                   string `json:"region"`
	AvailabilityZone         string `json:"availability_zone"`
	Deployment               string `json:"deployment"`
	RDSDefaultDatabaseName   string `json:"rds_default_database_name"`
	SourceAccessIP           string `json:"source_access_ip"`
	TFStatePath              string `json:"tf_state_path"`
	Project                  string `json:"project"`
	ConfigBucket             string `json:"config_bucket"`
	DirectorUsername         string `json:"director_username"`
	DirectorPassword         string `json:"director_password"`
	DirectorHMUserPassword   string `json:"director_hm_user_password"`
	DirectorMbusPassword     string `json:"director_mbus_password"`
	DirectorNATSPassword     string `json:"director_nats_password"`
	DirectorRegistryPassword string `json:"director_registry_password"`
	RDSInstanceClass         string `json:"rds_instance_class"`
	RDSUsername              string `json:"rds_username"`
	RDSPassword              string `json:"rds_password"`
	MultiAZRDS               bool   `json:"multi_az_rds"`
}

func generateDefaultConfig(project, deployment, region string) ([]byte, error) {
	privateKey, publicKey, err := util.GenerateSSHKeyPair()
	if err != nil {
		return nil, err
	}

	accessIP, err := util.FindUserIP()
	if err != nil {
		return nil, err
	}

	configBucket := fmt.Sprintf("%s-config", deployment)

	conf := Config{
		PublicKey:                strings.TrimSpace(string(publicKey)),
		PrivateKey:               strings.TrimSpace(string(privateKey)),
		Deployment:               deployment,
		ConfigBucket:             configBucket,
		RDSDefaultDatabaseName:   "bosh",
		SourceAccessIP:           accessIP,
		Project:                  project,
		TFStatePath:              terraformStateFileName,
		Region:                   region,
		AvailabilityZone:         fmt.Sprintf("%sa", region),
		DirectorUsername:         "admin",
		DirectorPassword:         util.GeneratePassword(),
		DirectorHMUserPassword:   util.GeneratePassword(),
		DirectorMbusPassword:     util.GeneratePassword(),
		DirectorNATSPassword:     util.GeneratePassword(),
		DirectorRegistryPassword: util.GeneratePassword(),
		RDSInstanceClass:         "db.t2.small",
		RDSUsername:              "admin" + util.GeneratePassword(),
		RDSPassword:              util.GeneratePassword(),
		MultiAZRDS:               false,
	}

	return json.MarshalIndent(&conf, "", "  ")
}