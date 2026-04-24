import '../api_client.dart';
import '../api_context.dart';
import '../api_endpoints.dart';
import '../models/acl_models.dart';
import '../models/common_models.dart';

class AclApiClient {
  AclApiClient(this._apiClient);

  final ApiClient _apiClient;

  static const _withToken = ApiRequestOptions(requiresAccessToken: true);

  Future<AclBootstrapResponse> getBootstrap(String petId) {
    return _apiClient.get<AclBootstrapResponse>(
      ApiEndpoints.aclBootstrap(petId),
      requestOptions: _withToken,
      decoder: AclBootstrapResponse.fromJson,
    );
  }

  Future<AclPresetListResponse> listPresets() {
    return _apiClient.get<AclPresetListResponse>(
      ApiEndpoints.aclPresets,
      requestOptions: _withToken,
      decoder: AclPresetListResponse.fromJson,
    );
  }

  Future<AclAccessResponse> getMyAccess(String petId) {
    return _apiClient.get<AclAccessResponse>(
      ApiEndpoints.aclMe(petId),
      requestOptions: _withToken,
      decoder: AclAccessResponse.fromJson,
    );
  }

  Future<EmptyResponse> leaveMyAccess(String petId) {
    return _apiClient.delete<EmptyResponse>(
      ApiEndpoints.aclMe(petId),
      requestOptions: _withToken,
      decoder: EmptyResponse.fromJson,
    );
  }

  Future<AclMemberListResponse> listMembers(String petId) {
    return _apiClient.get<AclMemberListResponse>(
      ApiEndpoints.aclMembers(petId),
      requestOptions: _withToken,
      decoder: AclMemberListResponse.fromJson,
    );
  }

  Future<AclMemberEnvelope> updateMember(
    String petId,
    String memberId,
    UpdateMemberPayload payload,
  ) {
    return _apiClient.patch<AclMemberEnvelope>(
      ApiEndpoints.aclMemberById(petId, memberId),
      data: payload.toJson(),
      requestOptions: _withToken,
      decoder: AclMemberEnvelope.fromJson,
    );
  }

  Future<EmptyResponse> removeMember(String petId, String memberId) {
    return _apiClient.delete<EmptyResponse>(
      ApiEndpoints.aclMemberById(petId, memberId),
      requestOptions: _withToken,
      decoder: EmptyResponse.fromJson,
    );
  }

  Future<AclRoleListResponse> listRoles(String petId) {
    return _apiClient.get<AclRoleListResponse>(
      ApiEndpoints.aclRoles(petId),
      requestOptions: _withToken,
      decoder: AclRoleListResponse.fromJson,
    );
  }

  Future<AclRoleEnvelope> createRole(String petId, CreateRolePayload payload) {
    return _apiClient.post<AclRoleEnvelope>(
      ApiEndpoints.aclRoles(petId),
      data: payload.toJson(),
      requestOptions: _withToken,
      decoder: AclRoleEnvelope.fromJson,
    );
  }

  Future<AclRoleEnvelope> updateRole(
    String petId,
    String roleId,
    UpdateRolePayload payload,
  ) {
    return _apiClient.patch<AclRoleEnvelope>(
      ApiEndpoints.aclRoleById(petId, roleId),
      data: payload.toJson(),
      requestOptions: _withToken,
      decoder: AclRoleEnvelope.fromJson,
    );
  }

  Future<EmptyResponse> deleteRole(String petId, String roleId) {
    return _apiClient.delete<EmptyResponse>(
      ApiEndpoints.aclRoleById(petId, roleId),
      requestOptions: _withToken,
      decoder: EmptyResponse.fromJson,
    );
  }

  Future<AclInviteListResponse> listInvites(String petId) {
    return _apiClient.get<AclInviteListResponse>(
      ApiEndpoints.aclInvites(petId),
      requestOptions: _withToken,
      decoder: AclInviteListResponse.fromJson,
    );
  }

  Future<AclInviteEnvelope> createInvite(
    String petId,
    CreateInvitePayload payload,
  ) {
    return _apiClient.post<AclInviteEnvelope>(
      ApiEndpoints.aclInvites(petId),
      data: payload.toJson(),
      requestOptions: _withToken,
      decoder: AclInviteEnvelope.fromJson,
    );
  }

  Future<EmptyResponse> revokeInvite(String petId, String inviteId) {
    return _apiClient.delete<EmptyResponse>(
      ApiEndpoints.aclInviteById(petId, inviteId),
      requestOptions: _withToken,
      decoder: EmptyResponse.fromJson,
    );
  }

  Future<AclInviteEnvelope> regenerateInviteLink(
    String petId,
    String inviteId,
  ) {
    return _apiClient.post<AclInviteEnvelope>(
      ApiEndpoints.aclInviteRegenerateLink(petId, inviteId),
      requestOptions: _withToken,
      decoder: AclInviteEnvelope.fromJson,
    );
  }

  Future<AclInvitePreviewResponse> previewInviteByToken(
    PreviewInviteByTokenPayload payload,
  ) {
    return _apiClient.post<AclInvitePreviewResponse>(
      ApiEndpoints.aclPreviewInviteByToken,
      data: payload.toJson(),
      requestOptions: _withToken,
      decoder: AclInvitePreviewResponse.fromJson,
    );
  }

  Future<AcceptInviteResponse> acceptInviteByCode(
    AcceptInviteByCodePayload payload,
  ) {
    return _apiClient.post<AcceptInviteResponse>(
      ApiEndpoints.aclAcceptInviteByCode,
      data: payload.toJson(),
      requestOptions: _withToken,
      decoder: AcceptInviteResponse.fromJson,
    );
  }

  Future<AcceptInviteResponse> acceptInviteByToken(
    AcceptInviteByTokenPayload payload,
  ) {
    return _apiClient.post<AcceptInviteResponse>(
      ApiEndpoints.aclAcceptInviteByToken,
      data: payload.toJson(),
      requestOptions: _withToken,
      decoder: AcceptInviteResponse.fromJson,
    );
  }
}
