import os
import sys
import requests

API_URL = "https://gitee.com/api/v5"


# https://gitee.com/api/v5/swagger#/postV5ReposOwnerRepoReleases


def getLatestRelease(access_token: str, owner: str, repo: str):
    try:
        res = requests.get(
            f"{API_URL}/repos/{owner}/{repo}/releases/latest",
            params={"access_token": access_token},
        )
        data = res.json()
        return {
            "id": data["id"],
            "tag_name": data["tag_name"],
            "data": data,
        }
    except:
        return None


def createRelease(
    access_token: str,
    owner: str,
    repo: str,
    tag_name: str,
    name: str,
    body: str,
    prerelease: bool,
    target_commitish: str,
):
    res = requests.post(
        f"{API_URL}/repos/{owner}/{repo}/releases",
        data={
            "access_token": access_token,
            "tag_name": tag_name,
            "name": name or tag_name,
            "body": body,
            "prerelease": prerelease,
            "target_commitish": target_commitish,
        },
    )
    data = res.json()
    return {
        "id": data["id"],
        "tag_name": data["tag_name"],
        "data": data,
    }


def updateRelease(
    access_token: str,
    owner: str,
    repo: str,
    tag_name: str,
    name: str,
    body: str,
    prerelease: bool,
    release_id: str,
):
    res = requests.patch(
        f"{API_URL}/repos/{owner}/{repo}/releases/{release_id}",
        data={
            "access_token": access_token,
            "tag_name": tag_name,
            "name": name or tag_name,
            "body": body,
            "prerelease": prerelease,
        },
    )
    data = res.json()
    return {
        "id": data["id"],
        "tag_name": data["tag_name"],
        "data": data,
    }


def deleteRelease(
    access_token: str,
    owner: str,
    repo: str,
    release_id: str,
):
    res = requests.delete(
        f"{API_URL}/repos/{owner}/{repo}/releases/{release_id}",
        params={
            "access_token": access_token,
        },
    )
    return res.status_code == 204


def uploadAttachFile(
    access_token: str,
    owner: str,
    repo: str,
    release_id: str,
    file_name: str,
    file_path: str,
):
    res = requests.post(
        f"{API_URL}/repos/{owner}/{repo}/releases/{release_id}/attach_files",
        data={
            "access_token": access_token,
        },
        files={"file": (file_name, open(file_path, "rb"))},
    )
    data = res.json()
    return {"id": data["id"], "data": data}


def deleteAttachFile(
    access_token: str, owner: str, repo: str, release_id: str, attach_file_id: str
):
    res = requests.delete(
        f"{API_URL}/repos/{owner}/{repo}/releases/{release_id}/attach_files/{attach_file_id}",
        params={
            "access_token": access_token,
        },
    )
    return res.status_code == 204


def syncRelease():
    (
        access_token,
        owner,
        repo,
        tag_name,
        name,
        body,
        prerelease,
        target_commitish,
        file_dir,
    ) = sys.argv[1:]
    body = body.replace("\\n", "\n")
    prerelease = prerelease == 1
    data = getLatestRelease(access_token, owner, repo)
    latest = True
    if data and data["tag_name"] == tag_name:
        if (
            data["data"]["name"] != name
            or data["data"]["body"] != body
            or data["data"]["prerelease"] != prerelease
        ):
            updateRelease(
                access_token,
                owner,
                repo,
                tag_name,
                name,
                body,
                prerelease,
                data["id"],
            )
    else:
        latest = False
        data = createRelease(
            access_token,
            owner,
            repo,
            tag_name,
            name,
            body,
            prerelease,
            target_commitish,
        )
    attachs = []
    try:
        for name in os.listdir(file_dir):
            if (
                latest
                and len(
                    [item for item in data["data"]["assets"] if item["name"] == name]
                )
                > 0
            ):
                print("exist equal name , continue")
                continue
            result = uploadAttachFile(
                access_token,
                owner,
                repo,
                data["id"],
                name,
                os.path.join(file_dir, name),
            )
            attachs.append(result["id"])
    except Exception as e:
        for id in attachs:
            deleteAttachFile(access_token, owner, repo, data["id"], id)
        raise Exception(f"sync fail, {e}")

if __name__ == "__main__":
    syncRelease()
