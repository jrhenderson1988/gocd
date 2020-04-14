/*
 * Copyright 2020 ThoughtWorks, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import {ErrorResponse} from "helpers/api_request_builder";
import m from "mithril";
import Stream from "mithril/stream";
import {Scms} from "models/materials/pluggable_scm";
import {Material} from "models/materials/types";
import {PackageRepositories} from "models/package_repositories/package_repositories";
import {Materials} from "models/pipeline_configs/pipeline_config";
import {PluginInfos} from "models/shared/plugin_infos_new/plugin_info";
import s from "underscore.string";
import {Cancel, Primary} from "views/components/buttons";
import {FlashMessage, MessageType} from "views/components/flash_message";
import {Modal, Size} from "views/components/modal";
import {MaterialEditor} from "views/pages/pipelines/material_editor";

export class MaterialModal extends Modal {
  private readonly materials: Stream<Materials>;
  protected readonly entity: Stream<Material>;
  private readonly __title: string;
  private readonly errorMessage: Stream<string>;
  private readonly pluginInfos: Stream<PluginInfos>;
  private readonly packageRepositories: Stream<PackageRepositories>;
  private readonly pluggableScms: Stream<Scms>;
  private readonly pipelineConfigSave: () => Promise<any>;
  private readonly isNew: boolean;

  constructor(title: string, entity: Stream<Material>, materials: Stream<Materials>, scms: Stream<Scms>,
              packages: Stream<PackageRepositories>, pluginInfos: Stream<PluginInfos>,
              pipelineConfigSave: () => Promise<any>, isNew: boolean) {
    super(Size.large);
    this.__title             = title;
    this.entity              = entity;
    this.pluggableScms       = scms;
    this.materials           = materials;
    this.packageRepositories = packages;
    this.pluginInfos         = pluginInfos;
    this.pipelineConfigSave  = pipelineConfigSave;
    this.isNew               = isNew;
    this.errorMessage        = Stream();
  }

  static forAdd(materials: Stream<Materials>, scms: Stream<Scms>, packageRepositories: Stream<PackageRepositories>,
                pluginInfos: Stream<PluginInfos>, onSuccessfulAdd: () => Promise<any>) {
    return new MaterialModal("Add material", Stream(new Material("git")), materials, scms, packageRepositories, pluginInfos, onSuccessfulAdd, true);
  }

  static forEdit(material: Material, materials: Stream<Materials>, scms: Stream<Scms>,
                 packageRepositories: Stream<PackageRepositories>, pluginInfos: Stream<PluginInfos>,
                 pipelineConfigSave: () => Promise<any>) {
    const title = `Edit material - ${s.capitalize(material.type()!)}`;
    return new MaterialModal(title, Stream(material), materials, scms, packageRepositories, pluginInfos, pipelineConfigSave, false);
  }

  title(): string {
    return this.__title;
  }

  body(): m.Children {
    return <div>
      <FlashMessage type={MessageType.alert} message={this.errorMessage()}/>
      <MaterialEditor material={this.entity()} showExtraMaterials={true} disabledMaterialTypeSelection={!this.isNew}
                      pluggableScms={this.pluggableScms()} packageRepositories={this.packageRepositories()} pluginInfos={this.pluginInfos()}/>
    </div>;
  }

  buttons(): m.ChildArray {
    return [
      <Primary data-test-id="button-save" onclick={this.addOrUpdateEntity.bind(this)}>Save</Primary>,
      <Cancel data-test-id="button-cancel" onclick={this.close.bind(this)}>Cancel</Cancel>
    ];
  }

  addOrUpdateEntity(): void {
    if (this.entity().isValid()) {
      if (this.isNew) {
        this.materials().push(this.entity());
      }

      this.pipelineConfigSave()
          .then(() => this.close())
          .catch((errorResponse: ErrorResponse) => {
            const parse = JSON.parse(errorResponse.body!);
            this.entity().consumeErrorsResponse(parse.data);
            this.errorMessage(parse.message);

            this.materials().delete(this.entity());
          });
    }
  }
}
