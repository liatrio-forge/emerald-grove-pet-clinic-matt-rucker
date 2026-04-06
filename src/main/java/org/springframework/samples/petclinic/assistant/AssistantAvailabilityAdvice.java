/*
 * Copyright 2012-2025 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.springframework.samples.petclinic.assistant;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

/**
 * Exposes an {@code assistantEnabled} model attribute to all Thymeleaf views so the chat
 * widget can be conditionally rendered based on whether the Anthropic API key is
 * configured.
 */
@ControllerAdvice
public class AssistantAvailabilityAdvice {

	private final boolean assistantEnabled;

	public AssistantAvailabilityAdvice(@Value("${spring.ai.anthropic.api-key:}") String apiKey) {
		this.assistantEnabled = apiKey != null && !apiKey.isBlank();
	}

	@ModelAttribute("assistantEnabled")
	public boolean isAssistantEnabled() {
		return this.assistantEnabled;
	}

}
