import '../api_client.dart';
import '../api_context.dart';
import '../api_endpoints.dart';
import '../models/acl_models.dart';
import '../models/common_models.dart';

class AclApiClient {
  AclApiClient(this._apiClient);

  final ApiClient _apiClient;

  static const _withUserAndToken = ApiRequestOptions(
    requiresUserId: true,
    requiresAccessToken: true,
  );

  Future<AclPresetListResponse> listPresets() {
    return _apiClient.get<AclPresetListResponse>(
      ApiEndpoints.aclPresets,
      requestOptions: _withUserAndToken,
      decoder: AclPresetListResponse.fromJson,
    );
  }

  Future<AclAccessResponse> getMyAccess(String petId) {
    return _apiClient.get<AclAccessResponse>(
      ApiEndpoints.aclMe(petId),
      requestOptions: _withUserAndToken,
      decoder: AclAccessResponse.fromJson,
    );
  }

  Future<AclMemberListResponse> listMembers(String petId) {
    return _apiClient.get<AclMemberListResponse>(
      ApiEndpoints.aclMembers(petId),
      requestOptions: _withUserAndToken,
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
      requestOptions: _withUserAndToken,
      decoder: AclMemberEnvelope.fromJson,
    );
  }

  Future<AclMemberEnvelope> removeMember(String petId, String memberId) {
    return _apiClient.delete<AclMemberEnvelope>(
      ApiEndpoints.aclMemberById(petId, memberId),
      requestOptions: _withUserAndToken,
      decoder: AclMemberEnvelope.fromJson,
    );
  }

  Future<AclRoleListResponse> listRoles(String petId) {
    return _apiClient.get<AclRoleListResponse>(
      ApiEndpoints.aclRoles(petId),
      requestOptions: _withUserAndToken,
      decoder: AclRoleListResponse.fromJson,
    );
  }

  Future<AclRoleEnvelope> createRole(String petId, CreateRolePayload payload) {
    return _apiClient.post<AclRoleEnvelope>(
      ApiEndpoints.aclRoles(petId),
      data: payload.toJson(),
      requestOptions: _withUserAndToken,
      decoder: AclRoleEnvelope.fromJson,
    );
  }

  Future<EmptyResponse> deleteRole(String petId, String roleId) {
    return _apiClient.delete<EmptyResponse>(
      ApiEndpoints.aclRoleById(petId, roleId),
      requestOptions: _withUserAndToken,
      decoder: EmptyResponse.fromJson,
    );
  }

  Future<AclInviteListResponse> listInvites(String petId) {
    return _apiClient.get<AclInviteListResponse>(
      ApiEndpoints.aclInvites(petId),
      requestOptions: _withUserAndToken,
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
      requestOptions: _withUserAndToken,
      decoder: AclInviteEnvelope.fromJson,
    );
  }

  Future<EmptyResponse> revokeInvite(String petId, String inviteId) {
    return _apiClient.delete<EmptyResponse>(
      ApiEndpoints.aclInviteById(petId, inviteId),
      requestOptions: _withUserAndToken,
      decoder: EmptyResponse.fromJson,
    );
  }

  Future<AcceptInviteResponse> acceptInviteByCode(
    AcceptInviteByCodePayload payload,
  ) {
    return _apiClient.post<AcceptInviteResponse>(
      ApiEndpoints.aclAcceptInviteByCode,
      data: payload.toJson(),
      requestOptions: _withUserAndToken,
      decoder: AcceptInviteResponse.fromJson,
    );
  }

  Future<AcceptInviteResponse> acceptInviteByToken(
    AcceptInviteByTokenPayload payload,
  ) {
    return _apiClient.post<AcceptInviteResponse>(
      ApiEndpoints.aclAcceptInviteByToken,
      data: payload.toJson(),
      requestOptions: _withUserAndToken,
      decoder: AcceptInviteResponse.fromJson,
    );
  }
}
